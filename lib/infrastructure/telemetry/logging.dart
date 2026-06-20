import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as logging;

export 'package:logging/logging.dart' hide Logger;

/// A custom wrapper around the standard `package:logging` Logger class.
///
/// It uses `@pragma('vm:prefer-inline')` and compile-time `kReleaseMode` checks
/// to enable the Dart compiler to tree-shake (compile out) debug-level logging calls
/// and their string arguments in release builds.
class Logger {
  final logging.Logger _inner;

  Logger(String name) : _inner = logging.Logger(name);

  static Logger get root => Logger(logging.Logger.root.name);

  // High-severity levels are always compiled in
  @pragma('vm:prefer-inline')
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    _inner.severe(message, error, stackTrace);
  }

  @pragma('vm:prefer-inline')
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    _inner.warning(message, error, stackTrace);
  }

  @pragma('vm:prefer-inline')
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) {
    _inner.shout(message, error, stackTrace);
  }

  // Low/verbose severity levels are stripped in release mode
  @pragma('vm:prefer-inline')
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _inner.info(message, error, stackTrace);
    }
  }

  @pragma('vm:prefer-inline')
  void config(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _inner.config(message, error, stackTrace);
    }
  }

  @pragma('vm:prefer-inline')
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _inner.fine(message, error, stackTrace);
    }
  }

  @pragma('vm:prefer-inline')
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _inner.finer(message, error, stackTrace);
    }
  }

  @pragma('vm:prefer-inline')
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _inner.finest(message, error, stackTrace);
    }
  }

  @pragma('vm:prefer-inline')
  void log(logging.Level logLevel, Object? message,
      [Object? error, StackTrace? stackTrace, Zone? zone]) {
    if (!kReleaseMode || logLevel >= logging.Level.WARNING) {
      _inner.log(logLevel, message, error, stackTrace, zone);
    }
  }

  bool isLoggable(logging.Level value) => _inner.isLoggable(value);
  logging.Level get level => _inner.level;
  set level(logging.Level? value) => _inner.level = value;
  Stream<logging.LogRecord> get onRecord => _inner.onRecord;
  String get name => _inner.name;
  Logger? get parent => _inner.parent != null ? Logger(_inner.parent!.name) : null;
  Map<String, Logger> get children => _inner.children.map((key, value) => MapEntry(key, Logger(value.name)));
}
