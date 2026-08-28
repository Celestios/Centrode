import 'package:centrode/shared/theme/design_tokens.dart';
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:centrode/src/rust/bridge/api.dart';

import 'log_models.dart';
import 'disk_writer.dart';
import 'error_handler.dart';

class LogManager {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();

  int _dartSeqId = 0;
  final List<LogPayload> _activeBuffer = [];
  Timer? _batchTimer;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;
  bool _initialized = false;
  static const Duration _deltaT = Duration(milliseconds: 500);
  static const int _handShakeTimeOut = 5;

  Future<void> _checkForPreviousPanics(String logPath) async {
    try {
      final file = File(logPath);
      if (!file.existsSync()) return;

      final contents = await file.readAsString();
      if (contents.contains('[RUST-FATAL]')) {
        final lines = contents.split('\n');
        final fatalLines = lines
            .where((l) => l.contains('[RUST-FATAL]'))
            .toList();

        for (final line in fatalLines) {
          developer.log(
            'Previous session crashed: $line',
            name: 'RustPanic',
            level: 2000,
          );
          _activeBuffer.add(
            LogPayload(
              time: DateTime.now().microsecondsSinceEpoch,
              seqId: _dartSeqId++,
              level: 5, // FATAL
              origin: LogOrigin.rust,
              message: 'PREVIOUS SESSION CRASH: $line',
            ),
          );
        }

        final crashArchive = File(
          '${file.path}.crash.${DateTime.now().millisecondsSinceEpoch}',
        );
        await file.rename(crashArchive.path);
        developer.log(
          'Archived previous crash log to ${crashArchive.path}',
          name: 'LogManager',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to check for previous panics: $e',
        name: 'LogManager',
      );
    }
  }

  Future<void> init() async {
    if (_initialized) {
      debugPrint('[LogManager] Already initialized, skipping.');
      return;
    }

    String logPath;
    if (!kReleaseMode &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      logPath = p.join(Directory.current.path, 'centrode.log');
    } else {
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null) {
          logPath = p.join(appData, 'centrode', 'centrode.log');
        } else {
          final supportDir = await getApplicationSupportDirectory();
          logPath = p.join(supportDir.path, 'centrode.log');
        }
      } else {
        final supportDir = await getApplicationSupportDirectory();
        logPath = p.join(supportDir.path, 'centrode.log');
      }
    }

    final logFile = File(logPath);
    if (!logFile.parent.existsSync()) {
      logFile.parent.createSync(recursive: true);
    }

    await _checkForPreviousPanics(logPath);
    final receivePort = ReceivePort();
    _isolateReceivePort = receivePort;
    final isolate = await Isolate.spawn(DiskWriter.diskWriterIsolate, [
      receivePort.sendPort,
      logPath,
    ]);

    _isolate = isolate;

    try {
      _isolateSendPort =
          await receivePort.first.timeout(
                const Duration(seconds: _handShakeTimeOut),
                onTimeout: () => throw TimeoutException(
                  'DiskWriter isolate handshake timeout',
                ),
              )
              as SendPort;
    } catch (e) {
      debugPrint('[LogManager] Fatal Isolate Initialization Failure: $e');
      isolate.kill(priority: Isolate.immediate);
      _isolateReceivePort?.close();
      _isolateReceivePort = null;
      _initialized = false;
      return;
    }

    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      final levelInt = _mapDartLevel(record.level);

      if (levelInt >= 3) {
        developer.log(
          record.message,
          level: record.level.value,
          name: LogOrigin.dart.label,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }

      var message = record.message;
      if (record.error != null) {
        message += '\nError: ${record.error}';
      }
      if (record.stackTrace != null) {
        message += '\nStackTrace:\n${record.stackTrace}';
      }

      _activeBuffer.add(
        LogPayload(
          time: DateTime.now().microsecondsSinceEpoch,
          seqId: _dartSeqId++,
          level: levelInt,
          origin: LogOrigin.dart,
          message: message,
        ),
      );

      if (levelInt >= 4) _flushBuffer();
    });

    // Delegate error boundaries Setup
    ErrorHandler.setupErrorHooks();

    try {
      await setupLogger();
      debugPrint('[LogManager] Rust logger setup complete.');
    } catch (e) {
      debugPrint('[LogManager] Rust logger setup failed: $e');
    }

    createLogStream().listen((rustLog) {
      if (rustLog.level >= 3) {
        developer.log(rustLog.message, level: rustLog.level, name: 'Rust');
      }

      _activeBuffer.add(
        LogPayload.fromRustLog(
          tMicro: rustLog.tMicro,
          seqId: rustLog.seqId,
          level: rustLog.level,
          message: rustLog.message,
        ),
      );

      if (rustLog.level >= 4) _flushBuffer();
    });

    debugPrint('[LogManager] Rust log stream connected.');

    _batchTimer = Timer.periodic(_deltaT, (_) => _flushBuffer());

    _initialized = true;
    debugPrint('[LogManager] Initialized successfully.');
  }

  void _flushBuffer() {
    if (_activeBuffer.isEmpty || _isolateSendPort == null) return;

    final chunk = List<LogPayload>.from(_activeBuffer);
    _activeBuffer.clear();
    chunk.sort();

    final payloadData = chunk.map((l) => l.toMap()).toList();
    _isolateSendPort?.send(payloadData);
  }

  Future<void> dispose() async {
    _batchTimer?.cancel();
    _flushBuffer();

    await Future.delayed(UiMotion.fast);

    _isolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();
  }

  int _mapDartLevel(Level level) {
    if (level >= Level.SHOUT) return 5; // FATAL
    if (level >= Level.SEVERE) return 4; // ERROR
    if (level >= Level.WARNING) return 3; // WARN
    if (level >= Level.INFO) return 2; // INFO
    if (level >= Level.CONFIG) return 2; // INFO
    if (level >= Level.FINE) return 1; // DEBUG
    if (level >= Level.FINER) return 0; // TRACE
    if (level >= Level.FINEST) return 0; // TRACE
    return 1; // Default to DEBUG
  }
}
