import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';
import 'package:centrode/presentation/theme/app_theme.dart';

void main() {
  group('ColorTheoryEngine Mathematical & Perceptual Invariants', () {
    const baseColor = Color(0xFF818CF8); // Indigo

    test('shiftHue correctly wraps around 360 degrees', () {
      final shifted360 = ColorTheoryEngine.shiftHue(baseColor, 360);
      expect(shifted360.value, equals(baseColor.value));

      final shiftedPositive = ColorTheoryEngine.shiftHue(baseColor, 180);
      expect(shiftedPositive.value, isNot(equals(baseColor.value)));

      final shiftedNegative = ColorTheoryEngine.shiftHue(baseColor, -180);
      expect(shiftedNegative.value, equals(shiftedPositive.value));
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

      expect(ColorTheoryEngine.bestContrastingTextColor(white), equals(Colors.black));
      expect(ColorTheoryEngine.bestContrastingTextColor(black), equals(Colors.white));
    });

    test('Hex to Color and Color to Hex round-trip conversion', () {
      const testColor = Color(0xFF34D399);
      final hex = ColorTheoryEngine.toHex(testColor);
      expect(hex, equals('#34D399'));

      final parsed = ColorTheoryEngine.tryParseHex(hex);
      expect(parsed?.value, equals(testColor.value));

      final shortHex = ColorTheoryEngine.tryParseHex('#FFF');
      expect(shortHex?.value, equals(0xFFFFFFFF));
    });
  });
}
