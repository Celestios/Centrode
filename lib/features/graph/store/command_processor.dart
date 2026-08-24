import 'dart:async';
import 'dart:collection';
import 'package:centrode/shared/logging.dart';
import '../models/models.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Manages the lifecycle of state mutations with FIFO ordering for FFI calls.
/// Implements write-behind debouncing to batch high-frequency spatial updates.
class CommandProcessor {
  static const int _debounceMs = 300;
  final Logger _log = Logger('CommandProcessor');
  final Map<String, Timer> _debouncers = {};
  final Map<String, GraphCommand> _pendingCommands = {};
  final ListQueue<GraphCommand> _executionQueue = ListQueue();
  final Function(String) onError;
  final void Function()? onQueueDrained;

  CommandProcessor({required this.onError, this.onQueueDrained});

  /// Generates a composite key from targetId and category to prevent
  /// different mutation types on the same node from overwriting each other.
  String _getCompositeKey(GraphCommand cmd) =>
      '${cmd.targetId}_${cmd.category.name}';

  void queueCommand(GraphCommand cmd, {bool immediate = false}) {
    final key = _getCompositeKey(cmd);

    _log.finer('Queueing command: ${cmd.runtimeType} [Key: $key]');

    _debouncers[key]?.cancel();
    _debouncers.remove(key);

    if (immediate) {
      _executionQueue.removeWhere((c) => _getCompositeKey(c) == key);
      _pendingCommands.remove(key);
      _executionQueue.addLast(cmd);
      _processQueue();
    } else {
      _pendingCommands[key] = cmd;
      _debouncers[key] = Timer(Duration(milliseconds: _debounceMs), () {
        final pending = _pendingCommands.remove(key);
        if (pending != null) {
          _log.fine(
            'Debounce timer fired for key: $key. Pushing to execution queue.',
          );
          _executionQueue.addLast(pending);
          _processQueue();
        }
      });
    }
  }

  Future<void>? _processingFuture;

  Future<void> _processQueue() async {
    if (_processingFuture != null) {
      return _processingFuture;
    }
    _log.info(
      'Starting _processQueue with ${_executionQueue.length} pending commands.',
    );
    final completer = Completer<void>();
    _processingFuture = completer.future;

    try {
      while (_executionQueue.isNotEmpty) {
        final cmd = _executionQueue.removeFirst();
        await cmd.execute();
        cmd.onSuccess();
      }
      completer.complete();
    } catch (e, stack) {
      _log.severe('FFI Synchronization command execution failed.', e, stack);
      completer.completeError(e, stack);
      rethrow;
    } finally {
      _processingFuture = null;
      onQueueDrained?.call();
    }
  }

  Future<void> flush() async {
    await forceFlush();
  }

  /// Forces execution of all pending debounced commands immediately.
  Future<void> forceFlush() async {
    for (var entry in _pendingCommands.entries) {
      _debouncers[entry.key]?.cancel();
      _executionQueue.addLast(entry.value);
    }
    _debouncers.clear();
    _pendingCommands.clear();
    await _processQueue();
  }

  void flushSync() {
    for (var timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    _executionQueue.clear();
    _pendingCommands.clear();
  }

  /// Notifies the processor that an ID swap has occurred.
  /// Updates any pending commands that reference the temp ID to use the real ID.
  /// This ensures commands queued during optimistic creation don't get trapped
  /// with the temp ID when the real ID becomes available.
  void notifyIdSwap(RawUuid tempId, RawUuid realId) {
    _log.fine('ID Swap notification: $tempId -> $realId');
    final tempStr = tempId.toUuidString();
    final realStr = realId.toUuidString();

    // 1. Update pending commands and their internal targetIds
    final keysToUpdate = <String>[];
    for (final entry in _pendingCommands.entries) {
      if (entry.value.targetId == tempId) {
        keysToUpdate.add(entry.key);
      }
    }

    for (final oldKey in keysToUpdate) {
      final cmd = _pendingCommands.remove(oldKey);
      if (cmd != null) {
        cmd.targetId = realId;
        final newKey = _getCompositeKey(cmd);
        _pendingCommands[newKey] = cmd;
        _log.fine('Updated pending command: $oldKey -> $newKey');
      }
    }

    // 2. Update commands already inside the Execution Queue
    for (final cmd in _executionQueue) {
      if (cmd.targetId == tempId) {
        _log.fine('Updating targetId in execution queue: $tempId -> $realId');
        cmd.targetId = realId;
      }
    }

    // 3. Update debouncers map keys
    final debouncerKeysToUpdate = <String, String>{};
    for (final key in _debouncers.keys) {
      if (key.contains(tempStr)) {
        debouncerKeysToUpdate[key] = key.replaceAll(tempStr, realStr);
      }
    }

    for (final oldKey in debouncerKeysToUpdate.keys) {
      final timer = _debouncers.remove(oldKey);
      if (timer != null) {
        _debouncers[debouncerKeysToUpdate[oldKey]!] = timer;
        _log.fine(
          'Updated debouncer key: $oldKey -> ${debouncerKeysToUpdate[oldKey]}',
        );
      }
    }
  }

  void dispose() {
    flushSync();
  }
}
