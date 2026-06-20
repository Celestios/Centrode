import 'package:flutter/foundation.dart';
import 'package:mycelium/infrastructure/telemetry/logging.dart';

class ErrorHandler {
  static void setupErrorHooks() {
    // Capture Flutter framework errors (e.g. layout, widget tree issues like missing Material)
    final flutterErrorLog = Logger('FlutterError');
    FlutterError.onError = (FlutterErrorDetails details) {
      flutterErrorLog.severe(
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
      // Present to console/screen as usual
      FlutterError.presentError(details);
    };

    // Capture uncaught asynchronous errors
    final asyncErrorLog = Logger('AsyncError');
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      asyncErrorLog.severe('Uncaught asynchronous error', error, stack);
      return true;
    };
  }
}
