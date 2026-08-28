import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Supported classical and modern color harmony types.
enum ColorHarmonyType {
  analogous,
  complementary,
  splitComplementary,
  triadic,
  tetradic,
  monochromatic,
}

/// Aesthetic mood profiles for generative palette exploration.
enum PaletteMood {
  vibrant,
  pastel,
  deep,
  warm,
  cool,
  neon,
  auto,
}

/// Representation of a color in the perceptually uniform OKLCH color space.
/// - [l]: Perceptual Lightness in [0.0, 1.0] (0 = black, 1 = white)
/// - [c]: Perceptual Chroma in [0.0, 0.4] (purity/saturation)
/// - [h]: Perceptual Hue angle in [0.0, 360.0) degrees
@immutable
class OklchColor {
  final double l;
  final double c;
  final double h;
  final double alpha;

  const OklchColor(this.l, this.c, this.h, [this.alpha = 1.0]);

  OklchColor copyWith({double? l, double? c, double? h, double? alpha}) {
    return OklchColor(
      l ?? this.l,
      c ?? this.c,
      h ?? this.h,
      alpha ?? this.alpha,
    );
  }

  /// Converts a standard Flutter [Color] (sRGB) into the perceptually uniform [OklchColor].
  factory OklchColor.fromColor(Color color) {
    // 1. Linearize sRGB
    double toLinear(double v) {
      return (v <= 0.04045) ? (v / 12.92) : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final rLin = toLinear(color.r);
    final gLin = toLinear(color.g);
    final bLin = toLinear(color.b);

    // 2. Linear sRGB to LMS
    final l = 0.4122214708 * rLin + 0.5363325363 * gLin + 0.0514459929 * bLin;
    final m = 0.2119034982 * rLin + 0.6806995451 * gLin + 0.1073969566 * bLin;
    final s = 0.0883024619 * rLin + 0.2817188376 * gLin + 0.6299787005 * bLin;

    // 3. Cube root non-linearity
    double cbrt(double v) => v < 0 ? -math.pow(-v, 1.0 / 3.0).toDouble() : math.pow(v, 1.0 / 3.0).toDouble();
    final lPrime = cbrt(l);
    final mPrime = cbrt(m);
    final sPrime = cbrt(s);

    // 4. LMS to Oklab (L, a, b)
    final labL = 0.2104542553 * lPrime + 0.7936177850 * mPrime - 0.0040720468 * sPrime;
    final labA = 1.9779984951 * lPrime - 2.4285922050 * mPrime + 0.4505937099 * sPrime;
    final labB = 0.0259040371 * lPrime + 0.7827717662 * mPrime - 0.8086757660 * sPrime;

    // 5. Oklab to OKLCH
    final chroma = math.sqrt(labA * labA + labB * labB);
    var hue = (math.atan2(labB, labA) * 180.0 / math.pi) % 360.0;
    if (hue < 0) hue += 360.0;

    return OklchColor(labL.clamp(0.0, 1.0), chroma.clamp(0.0, 0.4), hue, color.a);
  }

  /// Converts this [OklchColor] back into a Flutter [Color] (sRGB) with gamut clamping.
  Color toColor() {
    final hRad = h * math.pi / 180.0;
    final labA = c * math.cos(hRad);
    final labB = c * math.sin(hRad);

    // 1. Oklab to LMS'
    final lPrime = l + 0.3963377774 * labA + 0.2158037573 * labB;
    final mPrime = l - 0.1055613458 * labA - 0.0638541728 * labB;
    final sPrime = l - 0.0894841775 * labA - 1.2914855480 * labB;

    // 2. Cube
    final lLin = lPrime * lPrime * lPrime;
    final mLin = mPrime * mPrime * mPrime;
    final sLin = sPrime * sPrime * sPrime;

    // 3. LMS to Linear sRGB
    final rLin = 4.0767416621 * lLin - 3.3077115913 * mLin + 0.2309699292 * sLin;
    final gLin = -1.2684380046 * lLin + 2.6097574011 * mLin - 0.3413193965 * sLin;
    final bLin = -0.0041960863 * lLin - 0.7034186147 * mLin + 1.7076147010 * sLin;

    // 4. Gamma compression
    double toGamut(double v) {
      final clamped = v.clamp(0.0, 1.0);
      return (clamped <= 0.0031308)
          ? (clamped * 12.92)
          : (1.055 * math.pow(clamped, 1.0 / 2.4).toDouble() - 0.055);
    }

    final r = (toGamut(rLin) * 255.0).round().clamp(0, 255);
    final g = (toGamut(gLin) * 255.0).round().clamp(0, 255);
    final b = (toGamut(bLin) * 255.0).round().clamp(0, 255);
    final a = (alpha * 255.0).round().clamp(0, 255);

    return Color.fromARGB(a, r, g, b);
  }
}

/// Advanced Human-Perception Accurate Color Theory & Generative Palette Engine.
/// Calibrated against perceptual OKLCH color science and Coolors palette heuristics.
abstract final class ColorTheoryEngine {
  ColorTheoryEngine._();

  /// The Golden Angle in degrees: 360 * (1 - 1 / phi) ≈ 137.507764°
  static const double goldenAngle = 137.50776405003785;

  // ---------------------------------------------------------------------------
  // 1. Perceptually Uniform Harmonies (OKLCH Space)
  // ---------------------------------------------------------------------------

  /// Shifts the hue of a color in OKLCH space by [degrees] while strictly preserving
  /// human-perceived lightness and chroma.
  static Color shiftHue(Color color, double degrees) {
    final oklch = OklchColor.fromColor(color);
    var newHue = (oklch.h + degrees) % 360.0;
    if (newHue < 0) newHue += 360.0;
    return oklch.copyWith(h: newHue).toColor();
  }

  /// Generates Analogous harmony (±15°, ±30°) in perceptual OKLCH space.
  static List<Color> generateAnalogous(Color baseColor) {
    final oklch = OklchColor.fromColor(baseColor);
    return [
      shiftHue(baseColor, -30),
      shiftHue(baseColor, -15),
      baseColor,
      shiftHue(baseColor, 15),
      shiftHue(baseColor, 30),
    ];
  }

  /// Generates Complementary harmony (180° opposite) in perceptual OKLCH space.
  static List<Color> generateComplementary(Color baseColor) {
    final oklch = OklchColor.fromColor(baseColor);
    final complement = shiftHue(baseColor, 180);
    final compOklch = OklchColor.fromColor(complement);

    return [
      baseColor,
      oklch.copyWith(c: oklch.c * 0.65).toColor(),
      complement,
      compOklch.copyWith(l: (compOklch.l * 0.85).clamp(0.0, 1.0)).toColor(),
      compOklch.copyWith(c: compOklch.c * 0.50).toColor(),
    ];
  }

  /// Generates Split-Complementary harmony (150°, 210°) in perceptual OKLCH space.
  static List<Color> generateSplitComplementary(Color baseColor) {
    return [
      baseColor,
      shiftHue(baseColor, 150),
      shiftHue(baseColor, 210),
      shiftHue(baseColor, 165),
      shiftHue(baseColor, 195),
    ];
  }

  /// Generates Triadic harmony (120°, 240°) in perceptual OKLCH space.
  static List<Color> generateTriadic(Color baseColor) {
    final oklch = OklchColor.fromColor(baseColor);
    final c2 = shiftHue(baseColor, 120);
    final c3 = shiftHue(baseColor, 240);

    return [
      baseColor,
      c2,
      c3,
      OklchColor.fromColor(c2).copyWith(c: oklch.c * 0.65).toColor(),
      OklchColor.fromColor(c3).copyWith(c: oklch.c * 0.65).toColor(),
    ];
  }

  /// Generates Tetradic / Square harmony (90°, 180°, 270°) in perceptual OKLCH space.
  static List<Color> generateTetradic(Color baseColor) {
    return [
      baseColor,
      shiftHue(baseColor, 90),
      shiftHue(baseColor, 180),
      shiftHue(baseColor, 270),
    ];
  }

  /// Generates Monochromatic harmony: perfectly linear perceptual lightness steps in OKLCH.
  static List<Color> generateMonochromatic(Color baseColor, {int count = 5}) {
    final oklch = OklchColor.fromColor(baseColor);
    final List<Color> colors = [];

    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final newLightness = (0.35 + (t * 0.55)).clamp(0.0, 1.0);
      final newChroma = (oklch.c * (0.4 + (t * 0.6))).clamp(0.0, 0.4);
      colors.add(oklch.copyWith(l: newLightness, c: newChroma).toColor());
    }
    return colors;
  }

  /// Master harmony generator dispatching to [ColorHarmonyType].
  static List<Color> generateHarmony(Color baseColor, ColorHarmonyType type) {
    return switch (type) {
      ColorHarmonyType.analogous => generateAnalogous(baseColor),
      ColorHarmonyType.complementary => generateComplementary(baseColor),
      ColorHarmonyType.splitComplementary => generateSplitComplementary(baseColor),
      ColorHarmonyType.triadic => generateTriadic(baseColor),
      ColorHarmonyType.tetradic => generateTetradic(baseColor),
      ColorHarmonyType.monochromatic => generateMonochromatic(baseColor),
    };
  }

  // ---------------------------------------------------------------------------
  // 2. Generative Palette Exploration (Coolors Spacebar Experience + Slot Locking)
  // ---------------------------------------------------------------------------

  /// Generates a single aesthetically vibrant, non-muddy random color in OKLCH space.
  static Color generateHarmonicRandomColor({
    math.Random? random,
    double minLightness = 0.55,
    double maxLightness = 0.82,
    double minChroma = 0.12,
    double maxChroma = 0.22,
  }) {
    final rng = random ?? math.Random();
    final hue = (rng.nextDouble() * 360.0 + goldenAngle) % 360.0;
    final lightness = minLightness + (rng.nextDouble() * (maxLightness - minLightness));
    final chroma = minChroma + (rng.nextDouble() * (maxChroma - minChroma));

    return OklchColor(lightness, chroma, hue).toColor();
  }

  /// Generates an exploration palette supporting individual slot locking.
  /// When a slot is locked, its color is preserved; all unlocked slots are refreshed
  /// dynamically using Coolors-style 1-3-1 Lightness Rhythm and OKLCH Chroma Envelopes.
  static List<Color> generateThemedExplorationPalette({
    Color? primaryAnchor,
    List<Color?>? existingPalette,
    List<bool>? lockedSlots,
    PaletteMood mood = PaletteMood.auto,
    math.Random? random,
    int count = 5,
  }) {
    final rng = random ?? math.Random();

    // Determine the base seed hue
    final double baseHue;
    if (primaryAnchor != null) {
      final anchorOklch = OklchColor.fromColor(primaryAnchor);
      // Introduce an exploration drift unless locked
      baseHue = (anchorOklch.h + (rng.nextDouble() * 60.0 - 30.0)) % 360.0;
    } else {
      baseHue = rng.nextDouble() * 360.0;
    }

    final resolvedMood = (mood == PaletteMood.auto)
        ? PaletteMood.values[rng.nextInt(PaletteMood.values.length - 1)]
        : mood;

    // Chroma envelopes derived from our reverse-engineering analysis
    final (baseCMin, baseCMax) = switch (resolvedMood) {
      PaletteMood.vibrant => (0.15, 0.24),
      PaletteMood.pastel => (0.06, 0.11),
      PaletteMood.deep => (0.10, 0.18),
      PaletteMood.warm => (0.12, 0.20),
      PaletteMood.cool => (0.11, 0.19),
      PaletteMood.neon => (0.22, 0.32),
      PaletteMood.auto => (0.10, 0.20),
    };

    // The 1-3-1 Lightness Rhythm (Deep Anchor -> Mid Accents -> Light Highlight)
    final lightnessTargets = <double>[
      0.28 + rng.nextDouble() * 0.12, // Deep Anchor (28% - 40%)
      0.50 + rng.nextDouble() * 0.14, // Mid Accent 1
      0.62 + rng.nextDouble() * 0.14, // Mid Accent 2
      0.74 + rng.nextDouble() * 0.12, // Soft Bright Accent
      0.88 + rng.nextDouble() * 0.08, // High-Key Pastel/Tint (88% - 96%)
    ];

    // Hue generation using 70% Analogous flow + 1 Pop Accent
    final popIndex = rng.nextInt(count);
    final List<double> hues = [];
    for (int i = 0; i < count; i++) {
      if (i == popIndex) {
        // Pop accent: complementary or golden angle offset
        final popOffset = rng.nextBool() ? 180.0 : goldenAngle;
        hues.add((baseHue + popOffset + (rng.nextDouble() * 20.0 - 10.0)) % 360.0);
      } else {
        // Analogous flow
        final stepOffset = (i - count / 2) * (18.0 + rng.nextDouble() * 10.0);
        hues.add((baseHue + stepOffset) % 360.0);
      }
    }

    final List<Color> result = [];
    for (int i = 0; i < count; i++) {
      final isLocked = (lockedSlots != null && i < lockedSlots.length) ? lockedSlots[i] : false;
      final existingColor = (existingPalette != null && i < existingPalette.length) ? existingPalette[i] : null;

      if (isLocked && existingColor != null) {
        result.add(existingColor);
      } else {
        final l = lightnessTargets[i % lightnessTargets.length];
        final c = baseCMin + (rng.nextDouble() * (baseCMax - baseCMin));
        final h = hues[i % hues.length];
        result.add(OklchColor(l, c, h).toColor());
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // 3. Deterministic Theme-Derived Palette Generator
  // ---------------------------------------------------------------------------

  /// Deterministically derives 12 rich, coordinated swatches from theme anchor colors
  /// using OKLCH perceptual shifts (guarantees 100% stable UI colors).
  static List<Color> deriveThemePalette({
    required Color primary,
    required Color accent,
    required Color canvasAccent,
  }) {
    final primOklch = OklchColor.fromColor(primary);
    final accOklch = OklchColor.fromColor(accent);
    final canOklch = OklchColor.fromColor(canvasAccent);

    return [
      // 1-3: Anchor Accents
      primary,
      accent,
      canvasAccent,

      // 4-6: Perceptual Analogous Steps
      shiftHue(primary, 25),
      shiftHue(primary, -25),
      shiftHue(accent, 35),

      // 7-9: Perceptual Complementary & Triadic Steps
      shiftHue(primary, 180),
      shiftHue(accent, 120),
      shiftHue(canvasAccent, 240),

      // 10-12: High-Lightness Pastel / Micro Accents
      primOklch.copyWith(l: 0.85, c: primOklch.c * 0.6).toColor(),
      accOklch.copyWith(l: 0.82, c: accOklch.c * 0.6).toColor(),
      canOklch.copyWith(l: 0.80, c: canOklch.c * 0.6).toColor(),
    ];
  }

  // ---------------------------------------------------------------------------
  // 4. Perceptual Contrast & WCAG Utilities
  // ---------------------------------------------------------------------------

  /// Calculates WCAG relative luminance of a color in [0.0, 1.0].
  static double relativeLuminance(Color color) {
    double transform(double val) {
      return (val <= 0.03928) ? (val / 12.92) : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates the WCAG contrast ratio between two colors in [1.0, 21.0].
  static double contrastRatio(Color color1, Color color2) {
    final lum1 = relativeLuminance(color1);
    final lum2 = relativeLuminance(color2);
    final lighter = math.max(lum1, lum2);
    final darker = math.min(lum1, lum2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns [Colors.white] or [Colors.black] depending on optimal readability against [background].
  static Color bestContrastingTextColor(Color background) {
    final whiteContrast = contrastRatio(Colors.white, background);
    final blackContrast = contrastRatio(Colors.black, background);
    return (whiteContrast >= blackContrast) ? Colors.white : Colors.black;
  }

  // ---------------------------------------------------------------------------
  // 5. Hex Formatting & Parsing
  // ---------------------------------------------------------------------------

  /// Formats a [Color] into a `#RRGGBB` or `#AARRGGBB` hex string.
  static String toHex(Color color, {bool includeAlpha = false}) {
    final a = (color.a * 255.0).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = (color.r * 255.0).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = (color.g * 255.0).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = (color.b * 255.0).round().toRadixString(16).padLeft(2, '0').toUpperCase();

    return includeAlpha ? '#$a$r$g$b' : '#$r$g$b';
  }

  /// Parses a hex string (`#RGB`, `#RRGGBB`, `#AARRGGBB`) into a [Color].
  static Color? tryParseHex(String hex) {
    var clean = hex.trim().replaceAll('#', '');
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length != 8) return null;

    final intVal = int.tryParse(clean, radix: 16);
    if (intVal == null) return null;
    return Color(intVal);
  }
}
