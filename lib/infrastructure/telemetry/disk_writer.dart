import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'log_models.dart';

class DiskWriter {
  static const int rotationThreshold = 10 * 1024 * 1024; // 10MB

  static void diskWriterIsolate(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final logPath = args[1] as String;
    final isolateReceivePort = ReceivePort();

    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) {
      if (message is List) {
        performBatchWrite(message, logPath);
      }
    });
  }

  static void performBatchWrite(List<dynamic> batch, String logPath) {
    try {
      rotateFileIfNeeded(logPath);

      final buffer = StringBuffer();
      for (final item in batch) {
        if (item is Map<String, dynamic>) {
          final log = LogPayload.fromMap(item);
          buffer.writeln(log.toString());
        }
      }

      File(
        logPath,
      ).writeAsStringSync(buffer.toString(), mode: FileMode.append, flush: true);
    } catch (e) {
      developer.log(
        'Fatal background I/O failure: $e',
        name: 'DiskWriterIsolate',
      );
    }
  }

  static void rotateFileIfNeeded(String logPath) {
    final file = File(logPath);
    if (!file.existsSync() ||
        file.lengthSync() <= rotationThreshold) {
      return;
    }

    final oldFile = File('$logPath.old');
    if (oldFile.existsSync()) {
      oldFile.deleteSync();
    }
    file.renameSync('$logPath.old');
    File(logPath).createSync(recursive: true);

    developer.log(
      'Rotated log file: $logPath -> $logPath.old',
      name: 'DiskWriterIsolate',
    );
  }
}
