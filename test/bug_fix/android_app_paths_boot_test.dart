import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/app_paths.dart';

void main() {
  group('AppPaths platform dev root resolution', () {
    /// Pure logic evaluator matching AppPaths._appDataRoot condition:
    /// `!kReleaseMode && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)`
    bool isDevRootEligible({
      required bool isReleaseMode,
      required bool isWindows,
      required bool isLinux,
      required bool isMacOS,
    }) {
      return !isReleaseMode && (isWindows || isLinux || isMacOS);
    }

    test('Mobile platforms (Android/iOS) never qualify for dev root even in debug mode', () {
      // Android in debug mode
      expect(
        isDevRootEligible(
          isReleaseMode: false,
          isWindows: false,
          isLinux: false,
          isMacOS: false,
        ),
        isFalse,
      );

      // Android in release mode
      expect(
        isDevRootEligible(
          isReleaseMode: true,
          isWindows: false,
          isLinux: false,
          isMacOS: false,
        ),
        isFalse,
      );

      // iOS in debug mode
      expect(
        isDevRootEligible(
          isReleaseMode: false,
          isWindows: false,
          isLinux: false,
          isMacOS: false,
        ),
        isFalse,
      );

      // iOS in release mode
      expect(
        isDevRootEligible(
          isReleaseMode: true,
          isWindows: false,
          isLinux: false,
          isMacOS: false,
        ),
        isFalse,
      );
    });

    test('Desktop platforms qualify for dev root only in debug mode', () {
      // Windows debug vs release
      expect(
        isDevRootEligible(
          isReleaseMode: false,
          isWindows: true,
          isLinux: false,
          isMacOS: false,
        ),
        isTrue,
      );
      expect(
        isDevRootEligible(
          isReleaseMode: true,
          isWindows: true,
          isLinux: false,
          isMacOS: false,
        ),
        isFalse,
      );

      // Linux debug vs release
      expect(
        isDevRootEligible(
          isReleaseMode: false,
          isWindows: false,
          isLinux: true,
          isMacOS: false,
        ),
        isTrue,
      );
      expect(
        isDevRootEligible(
          isReleaseMode: true,
          isWindows: false,
          isLinux: true,
          isMacOS: false,
        ),
        isFalse,
      );

      // macOS debug vs release
      expect(
        isDevRootEligible(
          isReleaseMode: false,
          isWindows: false,
          isLinux: false,
          isMacOS: true,
        ),
        isTrue,
      );
      expect(
        isDevRootEligible(
          isReleaseMode: true,
          isWindows: false,
          isLinux: false,
          isMacOS: true,
        ),
        isFalse,
      );
    });

    test('Current host platform matches expected dev root eligibility', () {
      final currentIsDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final expected = !kReleaseMode && currentIsDesktop;
      expect(
        isDevRootEligible(
          isReleaseMode: kReleaseMode,
          isWindows: Platform.isWindows,
          isLinux: Platform.isLinux,
          isMacOS: Platform.isMacOS,
        ),
        equals(expected),
      );
    });

    test('AppPaths.getDevRoot resolves to project root containing pubspec.yaml on desktop', () async {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      if (isDesktop) {
        final root = await AppPaths.getDevRoot();
        expect(root, isNotEmpty);
        expect(File('$root/pubspec.yaml').existsSync(), isTrue);
      } else {
        expect(isDesktop, isFalse);
      }
    });
  });
}
