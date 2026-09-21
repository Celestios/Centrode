import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/presentation/theme/app_theme.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/theme/theme_surface_derivation.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dark Theme 5-Anchor System & Derivation Invariants', () {
    late AppTheme darkTheme;

    setUp(() {
      final file = File('assets/themes/dark.json');
      final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      darkTheme = AppTheme.fromMap(jsonMap);
    });

    test('dark.json loads all 5 independent anchors with zero fallbacks', () {
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.primaryColor, equals(const Color(0xFF818CF8)));
      expect(darkTheme.secondaryColor, equals(const Color(0xFF101216)));
      expect(darkTheme.tertiaryColor, equals(const Color(0xFFB49700)));
      expect(darkTheme.accentColor, equals(const Color(0xFFF43F5E)));
      expect(darkTheme.canvasAccentColor, equals(const Color(0xFF06B6D4)));
      final expectedSurfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
        primary: darkTheme.primaryColor,
        secondary: darkTheme.secondaryColor,
        tertiary: darkTheme.tertiaryColor,
        anchors: [
          darkTheme.primaryColor,
          darkTheme.secondaryColor,
          darkTheme.tertiaryColor,
          darkTheme.accentColor,
          darkTheme.canvasAccentColor,
        ],
      );
      expect(darkTheme.scaffoldBackgroundColor, equals(expectedSurfaces.scaffoldBackground));
      expect(darkTheme.cardColor, equals(expectedSurfaces.card));
      expect(darkTheme.dividerColor, equals(expectedSurfaces.divider));
      expect(darkTheme.textColor, equals(expectedSurfaces.text));
      expect(darkTheme.brightness, equals(expectedSurfaces.brightness));

      // AppTheme default constructor matches the default dark theme
      const defaultTheme = AppTheme();
      expect(defaultTheme.brightness, equals(Brightness.dark));
      expect(defaultTheme.primaryColor, equals(darkTheme.primaryColor));
      expect(defaultTheme.secondaryColor, equals(darkTheme.secondaryColor));
      expect(defaultTheme.tertiaryColor, equals(darkTheme.tertiaryColor));
      expect(defaultTheme.accentColor, equals(darkTheme.accentColor));
      expect(defaultTheme.canvasAccentColor, equals(darkTheme.canvasAccentColor));
    });

    test('All 5 anchors are distinct color values and chromatic accents have distinct hues', () {
      final colors = [
        darkTheme.primaryColor,
        darkTheme.secondaryColor,
        darkTheme.tertiaryColor,
        darkTheme.accentColor,
        darkTheme.canvasAccentColor,
      ];

      // No duplicate values
      final uniqueValues = colors.map((c) => c.toARGB32()).toSet();
      expect(uniqueValues.length, equals(5));

      // Chromatic accents (Primary, Tertiary, Accent, Canvas Accent) have distinct hues (>30° separation)
      final chromaticAccents = [
        darkTheme.primaryColor,
        darkTheme.tertiaryColor,
        darkTheme.accentColor,
        darkTheme.canvasAccentColor,
      ];
      final oklchs = chromaticAccents.map(OklchColor.fromColor).toList();
      for (int i = 0; i < oklchs.length; i++) {
        for (int j = i + 1; j < oklchs.length; j++) {
          final diff = ((oklchs[i].h - oklchs[j].h).abs()) % 360.0;
          final shortestDist = (diff > 180.0) ? (360.0 - diff) : diff;
          expect(shortestDist, greaterThan(30.0),
              reason: 'Color $i and $j hues are too close: ${oklchs[i].h}° vs ${oklchs[j].h}°');
        }
      }
    });

    test('primaryColor (Active Indigo) and tertiaryColor (Border Amber) form the 180° complementary axis', () {
      final primaryOklch = OklchColor.fromColor(darkTheme.primaryColor);
      final tertiaryOklch = OklchColor.fromColor(darkTheme.tertiaryColor);

      final diff = ((tertiaryOklch.h - primaryOklch.h).abs()) % 360.0;
      final shortestDist = (diff > 180.0) ? (360.0 - diff) : diff;

      expect(shortestDist, closeTo(180.0, 10.0));
    });

    test('CentrodeDerivedPalette maps the 5 anchors to specialized UI element tokens', () {
      final palette = CentrodeDerivedPalette.fromTheme(darkTheme);

      // Borders are adaptive neutral borders (crisp translucent white in dark theme)
      expect(palette.borderSubtle, equals(Colors.white.withValues(alpha: 0.12)));
      expect(palette.borderStrong, equals(Colors.white.withValues(alpha: 0.22)));

      // Semantic feedback mappings
      expect(palette.semantic.warning, equals(darkTheme.tertiaryColor));
      expect(palette.semantic.danger, equals(darkTheme.accentColor));
      expect(palette.semantic.info, equals(darkTheme.primaryColor));

      // Canvas element mappings
      expect(palette.canvas.selectionBorder, equals(darkTheme.primaryColor));
      expect(palette.canvas.containerBorder, equals(darkTheme.canvasAccentColor));
      expect(palette.canvas.frameBorder, equals(darkTheme.tertiaryColor));
      expect(palette.canvas.portIndicator, equals(darkTheme.canvasAccentColor));
      expect(palette.canvas.portIndicatorActive, equals(darkTheme.accentColor));

      // Tag colors include all 5 distinct anchors
      expect(palette.tagColors.length, equals(5));
      expect(palette.tagColors[0], equals(darkTheme.primaryColor));
      expect(palette.tagColors[1], equals(darkTheme.secondaryColor));
      expect(palette.tagColors[2], equals(darkTheme.tertiaryColor));
      expect(palette.tagColors[3], equals(darkTheme.accentColor));
      expect(palette.tagColors[4], equals(darkTheme.canvasAccentColor));
    });

    test('All text and interactive anchors pass WCAG AA contrast against dark surfaces', () {
      final textCard = ColorTheoryEngine.contrastRatio(darkTheme.textColor, darkTheme.cardColor);
      final textScaffold = ColorTheoryEngine.contrastRatio(darkTheme.textColor, darkTheme.scaffoldBackgroundColor);
      final primaryCard = ColorTheoryEngine.contrastRatio(darkTheme.primaryColor, darkTheme.cardColor);
      final tertiaryCard = ColorTheoryEngine.contrastRatio(darkTheme.tertiaryColor, darkTheme.cardColor);
      final accentCard = ColorTheoryEngine.contrastRatio(darkTheme.accentColor, darkTheme.cardColor);
      final canvasCard = ColorTheoryEngine.contrastRatio(darkTheme.canvasAccentColor, darkTheme.cardColor);

      expect(textCard, greaterThanOrEqualTo(7.0)); // WCAG AAA
      expect(textScaffold, greaterThanOrEqualTo(7.0)); // WCAG AAA
      expect(primaryCard, greaterThanOrEqualTo(4.5)); // WCAG AA
      expect(tertiaryCard, greaterThanOrEqualTo(4.5)); // WCAG AA
      expect(accentCard, greaterThanOrEqualTo(4.5)); // WCAG AA
      expect(canvasCard, greaterThanOrEqualTo(4.5)); // WCAG AA
    });

    test('Theme JSON files contain zero derivable surface or brightness keys', () {
      final themeDir = Directory('assets/themes');
      final themeFiles = themeDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      expect(themeFiles.length, greaterThanOrEqualTo(5));

      for (final file in themeFiles) {
        final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(jsonMap.containsKey('brightness'), isFalse, reason: '${file.path} should not contain brightness');
        expect(jsonMap.containsKey('scaffoldBackgroundColor'), isFalse, reason: '${file.path} should not contain scaffoldBackgroundColor');
        expect(jsonMap.containsKey('cardColor'), isFalse, reason: '${file.path} should not contain cardColor');
        expect(jsonMap.containsKey('dividerColor'), isFalse, reason: '${file.path} should not contain dividerColor');
        expect(jsonMap.containsKey('textColor'), isFalse, reason: '${file.path} should not contain textColor');
        expect(jsonMap.containsKey('bodyTextColor'), isFalse, reason: '${file.path} should not contain bodyTextColor');
        expect(jsonMap.containsKey('appBarBackgroundColor'), isFalse, reason: '${file.path} should not contain appBarBackgroundColor');
        expect(jsonMap.containsKey('appBarForegroundColor'), isFalse, reason: '${file.path} should not contain appBarForegroundColor');
      }
    });

    test('All bundled themes load without error and derive expected brightness', () {
      final themeDir = Directory('assets/themes');
      final themeFiles = themeDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      for (final file in themeFiles) {
        final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final theme = AppTheme.fromMap(jsonMap);
        final name = file.uri.pathSegments.last;

        if (name == 'light.json' || name == 'catppuccin_latte.json') {
          expect(theme.brightness, equals(Brightness.light), reason: '$name should be Brightness.light');
        } else {
          expect(theme.brightness, equals(Brightness.dark), reason: '$name should be Brightness.dark');
        }
      }
    });

    test('AppTheme.toMap serializes only 5 independent anchors with zero dead surface keys', () {
      final serialized = darkTheme.toMap();

      expect(serialized['primaryColor'], equals(darkTheme.primaryColor.toARGB32()));
      expect(serialized['secondaryColor'], equals(darkTheme.secondaryColor.toARGB32()));
      expect(serialized['tertiaryColor'], equals(darkTheme.tertiaryColor.toARGB32()));
      expect(serialized['accentColor'], equals(darkTheme.accentColor.toARGB32()));
      expect(serialized['canvasAccentColor'], equals(darkTheme.canvasAccentColor.toARGB32()));

      // Dead derivable surface keys must never be serialized
      expect(serialized.containsKey('brightness'), isFalse);
      expect(serialized.containsKey('scaffoldBackgroundColor'), isFalse);
      expect(serialized.containsKey('cardColor'), isFalse);
      expect(serialized.containsKey('dividerColor'), isFalse);
      expect(serialized.containsKey('textColor'), isFalse);
      expect(serialized.containsKey('bodyTextColor'), isFalse);
      expect(serialized.containsKey('appBarBackgroundColor'), isFalse);
      expect(serialized.containsKey('appBarForegroundColor'), isFalse);

      // Roundtrip reconstruction preserves all properties
      final reconstructed = AppTheme.fromMap(serialized);
      expect(reconstructed.primaryColor, equals(darkTheme.primaryColor));
      expect(reconstructed.secondaryColor, equals(darkTheme.secondaryColor));
      expect(reconstructed.tertiaryColor, equals(darkTheme.tertiaryColor));
      expect(reconstructed.accentColor, equals(darkTheme.accentColor));
      expect(reconstructed.canvasAccentColor, equals(darkTheme.canvasAccentColor));
      expect(reconstructed.brightness, equals(darkTheme.brightness));
      expect(reconstructed.scaffoldBackgroundColor, equals(darkTheme.scaffoldBackgroundColor));
      expect(reconstructed.cardColor, equals(darkTheme.cardColor));
    });
  });
}
