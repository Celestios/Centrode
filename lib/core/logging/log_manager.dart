/// Central Logger implementation for Mycelium.
///
/// This module implements the Asynchronous Observer with Isolate Handshake
/// and Pre-Stream Buffer pattern. It converges Flutter and Rust logs,
/// sorts them chronologically, and dispatches chunks to a writer isolate.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart'; // Import generated FFI

import 'log_models.dart';

/// Central logging manager implementing the batch router pattern.
///
/// The LogManager:
/// 1. Collects logs from both Rust (via FFI stream) and Dart (via logging package)
/// 2. Buffers logs in an active buffer with immediate DevTools mirror for L3+
/// 3. Flushes to a background isolate every 500ms (or immediately for L4/L5)
/// 4. The isolate handles sorting, formatting, and disk I/O
///
/// This ensures no frame jank during heavy logging operations.
class LogManager {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();

  /// Sequence ID counter for Dart-originated logs
  int _dartSeqId = 0;

  /// Active buffer for incoming logs
  final List<LogPayload> _activeBuffer = [];

  /// Timer for periodic buffer flush (TimeSlidingWindow)
  Timer? _batchTimer;

  /// SendPort for communicating with the background isolate
  late SendPort _isolateSendPort;

  /// Flag indicating if the manager has been initialized
  bool _initialized = false;

  // Constants from specifications
  static const Duration _deltaT = Duration(milliseconds: 500);
  static const int _rotationThreshold = 10 * 1024 * 1024; // 10MB

  /// Initializes the LogManager.
  ///
  /// This method:
  /// 1. Resolves platform-appropriate log file path
  /// 2. Spawns the background DiskWriter isolate with handshake
  /// 3. Sets up the Dart Logger sink
  /// 4. Connects to the Rust FFI log stream (if available)
  /// 5. Starts the periodic flush timer
  Future<void> init() async {
    if (_initialized) {
      debugPrint('[LogManager] Already initialized, skipping.');
      return;
    }

    // [FIX] Use Directory.current.path to place the log in the project root
    // matching the Rust panic hook path during local development.
    final logPath = '${Directory.current.path}/mycelium.log';

    // 2. Establish the Isolate Handshake with path payload
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _diskWriterIsolate,
      [receivePort.sendPort, logPath],
    );

    // Bounded wait to prevent main-thread startup deadlock
    try {
      _isolateSendPort = await receivePort.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('DiskWriter isolate handshake timeout'),
      ) as SendPort;
    } catch (e) {
      debugPrint('[LogManager] Fatal Isolate Initialization Failure: $e');
      _initialized = false;
      return;
    }

    // 2. Setup Dart Logger Sink
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final levelInt = _mapDartLevel(record.level);

      // Mirror warnings/errors to DevTools immediately
      if (levelInt >= 3) {
        developer.log(
          record.message,
          level: record.level.value,
          name: 'Dart',
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }

      _activeBuffer.add(LogPayload(
        time: DateTime.now().microsecondsSinceEpoch,
        seqId: _dartSeqId++,
        level: levelInt,
        origin: 'DART',
        message: record.message,
      ));

      if (levelInt >= 4) _flushBuffer(); // Emergency flush on ERROR/FATAL
    });

    // 3. Connect to Rust FFI Sink
    try {
      await setupLogger();
      debugPrint('[LogManager] Rust logger setup complete.');
    } catch (e) {
      debugPrint('[LogManager] Rust logger setup failed: $e');
    }

    // Stream activated with boundary type-system enforcement
    createLogStream().listen((rustLog) {
      if (rustLog.level >= 3) {
        developer.log(rustLog.message, level: rustLog.level, name: 'Rust');
      }

      _activeBuffer.add(LogPayload(
        time: rustLog.tMicro,
        // Enforced Downcast: FRB translates Rust u64 -> Dart BigInt
        seqId: rustLog.sId is BigInt ? (rustLog.sId as dynamic).toInt() : rustLog.sId as int,
        level: rustLog.level,
        origin: 'RUST',
        message: rustLog.message,
      ));

      if (rustLog.level >= 4) _flushBuffer(); // Emergency flush on ERROR/FATAL
    });

    debugPrint('[LogManager] Rust log stream connected.');

    // 4. Start Time-Sliding Batch Window
    _batchTimer = Timer.periodic(_deltaT, (_) => _flushBuffer());

    _initialized = true;
    debugPrint('[LogManager] Initialized successfully.');
  }

  /// Flushes the active buffer to the background isolate.
  ///
  /// This implements the buffer swap:
  /// 1. Swap active buffer with an empty buffer
  /// 2. Sort the frozen buffer (T → Origin → SeqID)
  /// 3. Dispatch to isolate for I/O
  void _flushBuffer() {
    if (_activeBuffer.isEmpty) return;

    // Freeze current buffer and swap
    final chunk = List<LogPayload>.from(_activeBuffer);
    _activeBuffer.clear();

    // Sort: T → Origin → SeqID
    chunk.sort((a, b) {
      final tCmp = a.time.compareTo(b.time);
      if (tCmp != 0) return tCmp;
      final origCmp = a.origin.compareTo(b.origin);
      if (origCmp != 0) return origCmp;
      return a.seqId.compareTo(b.seqId);
    });

    // Serialize to plain list for Isolate messaging
    final payloadData = chunk
        .map((l) => [l.time, l.seqId, l.level, l.origin, l.message])
        .toList();
    _isolateSendPort.send(payloadData);
  }

  /// Maps Dart logging Level to integer log level.
  int _mapDartLevel(Level l) {
    if (l >= Level.SEVERE) return 4;
    if (l >= Level.WARNING) return 3;
    if (l >= Level.INFO) return 2;
    if (l >= Level.FINE) return 1;
    return 0; // TRACE
  }

  /// Disposes the LogManager, flushing any remaining logs.
  Future<void> dispose() async {
    _batchTimer?.cancel();

    // Final flush
    _flushBuffer();

    // Give the isolate a moment to write final logs
    await Future.delayed(const Duration(milliseconds: 100));

    _initialized = false;
  }
}

// --- BACKGROUND ISOLATE ENTRY POINT ---

/// Entry point for the background disk writer isolate.
///
/// Performs the handshake by sending its SendPort back to the main thread,
/// then listens for log batches to write to disk.
///
/// Args[0]: SendPort for handshake response
/// Args[1]: String path to log file (resolved from main thread)
void _diskWriterIsolate(List<dynamic> args) {
  final mainSendPort = args[0] as SendPort;
  final logPath = args[1] as String;

  final isolateReceivePort = ReceivePort();

  // Handshake Step 2: Send port back to main thread
  mainSendPort.send(isolateReceivePort.sendPort);

  // Use platform-appropriate path passed from main thread
  final file = File(logPath);

  isolateReceivePort.listen((message) {
    if (message is List) {
      _performBatchWrite(message, file);
    }
  });
}

/// Performs batch write of logs to disk.
///
/// This runs in the background isolate and handles:
/// 1. Deserializing log entries
/// 2. File rotation if size exceeds threshold
/// 3. Writing to disk with flush
void _performBatchWrite(List<dynamic> batch, File file) {
  // Disk Space Exhaustion / Rotation Logic
  try {
    if (file.existsSync() && file.lengthSync() > LogManager._rotationThreshold) {
      final oldFile = File('${file.path}.old');
      if (oldFile.existsSync()) {
        oldFile.deleteSync();
      }
      file.renameSync('${file.path}.old');
    }
  } catch (e) {
    // If rotation fails, continue with write
  }

  // Build output buffer
  final buffer = StringBuffer();
  for (final item in batch) {
    if (item is List && item.length >= 5) {
      final ts = DateTime.fromMicrosecondsSinceEpoch(item[0] as int);
      final sid = item[1];
      final lvl = item[2];
      final origin = item[3];
      final msg = item[4];

      buffer.writeln('[${ts.toIso8601String()}] [$lvl] [$origin-$sid] $msg');
    }
  }

  // Append mode, synchronous block to guarantee order inside isolate
  try {
    file.writeAsStringSync(
      buffer.toString(),
      mode: FileMode.append,
      flush: true,
    );
  } catch (e) {
    // Route isolate I/O exceptions back to the VM dev console
    developer.log('Fatal background I/O failure: $e', name: 'DiskWriterIsolate');
  }
}
