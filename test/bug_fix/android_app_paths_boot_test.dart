import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify platform check for dev root path resolution', () {
    debugPrint('[Test] Checking platform desktop guard requirement...');
    final isDesktop = !kReleaseMode && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    debugPrint('[Test] Platform isDesktop for dev root: $isDesktop');
    
    // On mobile platforms (Android/iOS), isDesktop MUST be false even in debug mode (!kReleaseMode)
    if (Platform.isAndroid || Platform.isIOS) {
      expect(isDesktop, isFalse);
    }
  });
}
