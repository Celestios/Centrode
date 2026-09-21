import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/theme/theme_surface_derivation.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

void main() {
  group('ColorTheoryEngine Mathematical & Perceptual Invariants', () {
    const baseColor = Color(0xFF818CF8); // Indigo

    test('shiftHue correctly wraps around 360 degrees', () {
      final shifted360 = ColorTheoryEngine.shiftHue(baseColor, 360);
      expect(shifted360.toARGB32(), equals(baseColor.toARGB32()));

      final shiftedPositive = ColorTheoryEngine.shiftHue(baseColor, 180);
      expect(shiftedPositive.toARGB32(), isNot(equals(baseColor.toARGB32())));

      final shiftedNegative = ColorTheoryEngine.shiftHue(baseColor, -180);
      expect(shiftedNegative.toARGB32(), equals(shiftedPositive.toARGB32()));
    });

    test('generateAnalogous returns 5 harmonious adjacent colors', () {
      final palette = ColorTheoryEngine.generateAnalogous(baseColor);
      expect(palette.length, equals(5));
      expect(palette[2], equals(baseColor)); // Center is base color
    });

    test('generateComplementary returns base and opposite complement colors', () {
      final palette = ColorTheoryEngine.generateComplementary(baseColor);
      expect(palette.length, equals(5));
      expect(palette[0], equals(baseColor));
    });

    test('generateTriadic returns 5 triadic harmonic shades', () {
      final palette = ColorTheoryEngine.generateTriadic(baseColor);
      expect(palette.length, equals(5));
      expect(palette[0], equals(baseColor));
    });

    test('generateTetradic returns 4 square harmonic colors', () {
      final palette = ColorTheoryEngine.generateTetradic(baseColor);
      expect(palette.length, equals(4));
      expect(palette[0], equals(baseColor));
    });

    test('generateMonochromatic generates smooth luminance steps', () {
      final palette = ColorTheoryEngine.generateMonochromatic(baseColor, count: 6);
      expect(palette.length, equals(6));
      for (int i = 0; i < palette.length - 1; i++) {
        expect(palette[i], isNot(equals(palette[i + 1])));
      }
    });

    test('generateHarmonicRandomColor produces aesthetic non-zero colors', () {
      final randoms = List.generate(20, (_) => ColorTheoryEngine.generateHarmonicRandomColor());
      for (final color in randoms) {
        final oklch = OklchColor.fromColor(color);
        expect(oklch.l, inInclusiveRange(0.30, 0.90));
        expect(oklch.c, greaterThanOrEqualTo(0.06));
      }
    });

    test('generateThemedExplorationPalette generates cohesive theme-anchored exploration palettes with slot locking', () {
      final exploration = ColorTheoryEngine.generateThemedExplorationPalette(
        primaryAnchor: const Color(0xFF6366F1),
        mood: PaletteMood.vibrant,
        count: 5,
      );
      expect(exploration.length, equals(5));

      for (final color in exploration) {
        final oklch = OklchColor.fromColor(color);
        expect(oklch.l, inInclusiveRange(0.20, 0.98));
      }

      // Test with locked slot
      final lockedExploration = ColorTheoryEngine.generateThemedExplorationPalette(
        existingPalette: exploration,
        lockedSlots: [true, false, false, false, false],
        count: 5,
      );
      expect(lockedExploration[0], equals(exploration[0]));
    });

    test('deriveThemePalette generates 12 harmonious swatches from theme', () {
      final swatches = ColorTheoryEngine.deriveThemePalette(
        primary: const Color(0xFF6366F1),
        accent: const Color(0xFF10B981),
        canvasAccent: const Color(0xFFF59E0B),
      );
      expect(swatches.length, equals(12));
      expect(swatches[0], equals(const Color(0xFF6366F1)));
      expect(swatches[1], equals(const Color(0xFF10B981)));
      expect(swatches[2], equals(const Color(0xFFF59E0B)));
    });

    test('WCAG Relative Luminance and Contrast Ratio calculation', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);

      expect(ColorTheoryEngine.relativeLuminance(white), closeTo(1.0, 0.01));
      expect(ColorTheoryEngine.relativeLuminance(black), closeTo(0.0, 0.01));

      final contrast = ColorTheoryEngine.contrastRatio(white, black);
      expect(contrast, closeTo(21.0, 0.1));

      expect(ColorTheoryEngine.bestContrastingTextColor(white), equals(const Color(0xFF0F172A)));
      expect(ColorTheoryEngine.bestContrastingTextColor(black), equals(const Color(0xFFF8FAFC)));
    });

    test('Hex to Color and Color to Hex round-trip conversion', () {
      const testColor = Color(0xFF34D399);
      final hex = ColorTheoryEngine.toHex(testColor);
      expect(hex, equals('#34D399'));

      final parsed = ColorTheoryEngine.tryParseHex(hex);
      expect(parsed?.toARGB32(), equals(testColor.toARGB32()));

      final shortHex = ColorTheoryEngine.tryParseHex('#FFF');
      expect(shortHex?.toARGB32(), equals(0xFFFFFFFF));
    });

    test('deriveBrightness distinguishes dark from light themes based on secondary background anchor', () {
      // Dark theme anchors: secondaryColor is the dark background (0xFF101216)
      const darkAnchors = [
        Color(0xFF818CF8), // primary: active
        Color(0xFF101216), // secondary: background (dark)
        Color(0xFFB49700), // tertiary: borders
        Color(0xFFF43F5E), // accent: alert
        Color(0xFF06B6D4), // canvasAccent: tools
      ];
      expect(ThemeSurfaceDerivation.deriveBrightness(darkAnchors), equals(Brightness.dark));

      // Light theme anchors: secondaryColor is the light background (0xFFF8FAFC)
      const lightAnchors = [
        Color(0xFF1976D2), // primary: active
        Color(0xFFF8FAFC), // secondary: background (light)
        Color(0xFFCBD5E1), // tertiary: borders
        Color(0xFFD81B60), // accent: alert
        Color(0xFF0097A7), // canvasAccent: tools
      ];
      expect(ThemeSurfaceDerivation.deriveBrightness(lightAnchors), equals(Brightness.light));
    });

    test('deriveThemeSurfaces generates surfaces and borders from secondary and tertiary anchors', () {
      const primary = Color(0xFF818CF8);
      const secondary = Color(0xFF101216);
      const tertiary = Color(0xFFB49700);
      const anchors = [
        primary,
        secondary,
        tertiary,
        Color(0xFFF43F5E),
        Color(0xFF06B6D4),
      ];

      final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        anchors: anchors,
      );

      expect(surfaces.brightness, equals(Brightness.dark));
      // Scaffold is secondary directly
      expect(surfaces.scaffoldBackground, equals(secondary));
      // Card is slightly more elevated/luminous than scaffold
      expect(ColorTheoryEngine.relativeLuminance(surfaces.card),
          greaterThanOrEqualTo(ColorTheoryEngine.relativeLuminance(surfaces.scaffoldBackground)));
      // In dark theme, control buttons are recessed/darker than the scaffold
      expect(ColorTheoryEngine.relativeLuminance(surfaces.control),
          lessThanOrEqualTo(ColorTheoryEngine.relativeLuminance(surfaces.scaffoldBackground)));
      // Text on control surface has AAA contrast
      final controlText = ColorTheoryEngine.bestContrastingTextColor(surfaces.control);
      expect(ColorTheoryEngine.contrastRatio(controlText, surfaces.control), greaterThanOrEqualTo(7.0));
      // Workspace background is pure black (L=0) in dark mode
      expect(surfaces.workspaceBackground, equals(const Color(0xFF000000)));
      // Panel is secondary anchor
      expect(surfaces.panel, equals(secondary));
      // Divider has a distinct subtle tone decoupled from the tertiary border
      expect(surfaces.divider, isNot(equals(tertiary)));
      // Text contrast is >= 7.0 (AAA)
      expect(ColorTheoryEngine.contrastRatio(surfaces.text, surfaces.card), greaterThanOrEqualTo(7.0));
      expect(ColorTheoryEngine.contrastRatio(surfaces.text, surfaces.scaffoldBackground), greaterThanOrEqualTo(7.0));
    });

    test('deriveThemeSurfaces generates brighter control buttons in light mode and preserves green tint', () {
      const primary = Color(0xFF2563EB);
      const secondary = Color(0xFFEAECEF); // Light theme
      const tertiary = Color(0xFFD97706);
      const anchors = [
        primary,
        secondary,
        tertiary,
        Color(0xFFDC2626),
        Color(0xFF0284C7),
      ];

      final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        anchors: anchors,
      );

      expect(surfaces.brightness, equals(Brightness.light));
      // In light theme, control buttons are elevated/brighter than the secondary canvas
      expect(ColorTheoryEngine.relativeLuminance(surfaces.control),
          greaterThanOrEqualTo(ColorTheoryEngine.relativeLuminance(surfaces.scaffoldBackground)));
      // Text on control surface in light theme has AAA contrast
      final controlText = ColorTheoryEngine.bestContrastingTextColor(surfaces.control);
      expect(ColorTheoryEngine.contrastRatio(controlText, surfaces.control), greaterThanOrEqualTo(7.0));
      // Workspace background is an eye-friendly soft off-white canvas (L ≈ 0.965)
      expect(ColorTheoryEngine.relativeLuminance(surfaces.workspaceBackground), greaterThan(0.85));
      expect(ColorTheoryEngine.relativeLuminance(surfaces.workspaceBackground), lessThan(1.0));
      // Card is pure / near-pure white (L ≈ 0.995) floating on top of the soft canvas
      expect(ColorTheoryEngine.relativeLuminance(surfaces.card), greaterThan(ColorTheoryEngine.relativeLuminance(surfaces.workspaceBackground)));
      // Panel is elevated and brighter than secondary anchor in light mode
      expect(ColorTheoryEngine.relativeLuminance(surfaces.panel), greaterThanOrEqualTo(ColorTheoryEngine.relativeLuminance(secondary)));

      // Green tinted secondary preserves hue in both dark and light modes
      const darkGreenSec = Color(0xFF102416);
      final darkGreenSurfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
        primary: const Color(0xFF818CF8),
        secondary: darkGreenSec,
        tertiary: const Color(0xFFB49700),
        anchors: [const Color(0xFF818CF8), darkGreenSec, const Color(0xFFB49700), const Color(0xFFF43F5E), const Color(0xFF06B6D4)],
      );
      expect(darkGreenSurfaces.brightness, equals(Brightness.dark));
      expect(ColorTheoryEngine.relativeLuminance(darkGreenSurfaces.control),
          lessThanOrEqualTo(ColorTheoryEngine.relativeLuminance(darkGreenSec)));
    });
  });
}
