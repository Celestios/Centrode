import 'dart:async';
import 'package:centrode/shared/logging.dart';
import '../api/history_api.dart';
import '../command_processor.dart';

/// Command handler managing undo/redo history operations and status synchronization.
class HistoryCommandHandler {
  final Logger _log = Logger('HistoryCommandHandler');
  final HistoryApi _api;
  final CommandProcessor _processor;
  final void Function()? onHistoryUpdated;

  int _undoCount = 0;
  int _redoCount = 0;

  HistoryCommandHandler({
    required HistoryApi api,
    required CommandProcessor processor,
    this.onHistoryUpdated,
  })  : _api = api,
        _processor = processor;

  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  /// Fetches and updates latest undo/redo counts from the backend.
  Future<void> updateHistoryStatus() async {
    _undoCount = await _api.undoCount();
    _redoCount = await _api.redoCount();
    onHistoryUpdated?.call();
  }

  /// Executes an undo operation on the backend.
  Future<void> undo() async {
    _log.info('Executing undo');
    await _processor.flush();
    await _api.undo();
    await updateHistoryStatus();
  }

  /// Executes a redo operation on the backend.
  Future<void> redo() async {
    _log.info('Executing redo');
    await _processor.flush();
    await _api.redo();
    await updateHistoryStatus();
  }
}
