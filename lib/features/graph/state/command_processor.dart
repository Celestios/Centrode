import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import '../domain/models.dart';

/// Manages the lifecycle of state mutations with FIFO ordering for FFI calls.
/// Implements write-behind debouncing to batch high-frequency spatial updates.
class CommandProcessor {
  final Logger _log = Logger('CommandProcessor');
  final Map<String, Timer> _debouncers = {};
  final Map<String, GraphCommand> _pendingCommands = {};
  final ListQueue<GraphCommand> _executionQueue = ListQueue();
  bool _isProcessing = false;
  final Function(String) onError;

  CommandProcessor({required this.onError});

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
      _debouncers[key] = Timer(const Duration(milliseconds: 300), () {
        final pending = _pendingCommands.remove(key);
        if (pending != null) {
          _executionQueue.addLast(pending);
          _processQueue();
        }
      });
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_executionQueue.isNotEmpty) {
      final cmd = _executionQueue.removeFirst();
      final key = _getCompositeKey(cmd);
      try {
        await cmd.execute();
        if (cmd is MoveNodeCommand) cmd.onSuccess();
      } catch (e) {
        _log.severe(
          'FFI Synchronization failed for ${cmd.targetId}. Rollback.',
          e,
        );
        cmd.undo();
        _executionQueue.removeWhere((c) => _getCompositeKey(c) == key);
        _pendingCommands.remove(key);
        onError("Sync failed: $e");
      }
    }
    _isProcessing = false;
  }

  Future<void> flush() async {
    flushSync();
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
  void notifyIdSwap(String tempId, String realId) {
    _log.fine('ID Swap notification: $tempId -> $realId');

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
        // Update the command's internal ID so the FFI call uses the real one
        cmd.targetId = realId;

        // Re-insert with the new composite key
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
      if (key.contains(tempId)) {
        debouncerKeysToUpdate[key] = key.replaceAll(tempId, realId);
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
}
