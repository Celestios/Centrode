import 'dart:async';
import 'package:centrode/src/rust/repo/history.dart';

abstract interface class HistoryApi {
  Future<HistoryRecord?> undo();
  Future<int> undoCount();
  Future<HistoryRecord?> redo();
  Future<int> redoCount();
}
