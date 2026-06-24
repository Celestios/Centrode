import 'package:flutter/material.dart';

enum ColorHarmonyType {
  monochromatic,
  analogous,
  complementary,
  triadic,
}

class ColorHarmonyGenerator {
  /// Shift hue by a specific degree amount (0-360 range wrap)
  static HSVColor _shiftHue(HSVColor base, double degrees) {
    final newHue = (base.hue + degrees) % 360.0;
    return base.withHue(newHue);
  }

  /// Generate Monochromatic harmony (same hue, varying saturation and value/brightness)
  static List<Color> generateMonochromatic(Color baseColor, {int count = 5}) {
    final hsv = HSVColor.fromColor(baseColor);
    final List<Color> colors = [];
    
    // Vary saturation and value evenly to create a cohesive scale
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final newSaturation = (0.2 + (t * 0.8)).clamp(0.0, 1.0);
      final newValue = (0.9 - (t * 0.6)).clamp(0.0, 1.0);
      colors.add(hsv.withSaturation(newSaturation).withValue(newValue).toColor());
    }
    return colors;
  }

  /// Generate Analogous harmony (hue offset by ±30 and ±15 degrees)
  static List<Color> generateAnalogous(Color baseColor) {
    final hsv = HSVColor.fromColor(baseColor);
    return [
      _shiftHue(hsv, -30).toColor(),
      _shiftHue(hsv, -15).toColor(),
      baseColor,
      _shiftHue(hsv, 15).toColor(),
      _shiftHue(hsv, 30).toColor(),
    ];
  }

  /// Generate Complementary harmony (base color + opposite hue 180 degrees)
  static List<Color> generateComplementary(Color baseColor) {
    final hsv = HSVColor.fromColor(baseColor);
    // Return monochromatic variations of the complement along with base to make a rich set
    final complement = _shiftHue(hsv, 180);
    return [
      baseColor,
      hsv.withSaturation((hsv.saturation * 0.6).clamp(0.0, 1.0)).toColor(),
      complement.toColor(),
      complement.withValue((complement.value * 0.7).clamp(0.0, 1.0)).toColor(),
    ];
  }

  /// Generate Triadic harmony (three colors spaced 120 degrees apart)
  static List<Color> generateTriadic(Color baseColor) {
    final hsv = HSVColor.fromColor(baseColor);
    return [
      baseColor,
      _shiftHue(hsv, 120).toColor(),
      _shiftHue(hsv, 240).toColor(),
    ];
  }

  /// Master generator function based on selected harmony type
  static List<Color> generateHarmony(Color baseColor, ColorHarmonyType type) {
    switch (type) {
      case ColorHarmonyType.monochromatic:
        return generateMonochromatic(baseColor);
      case ColorHarmonyType.analogous:
        return generateAnalogous(baseColor);
      case ColorHarmonyType.complementary:
        return generateComplementary(baseColor);
      case ColorHarmonyType.triadic:
        return generateTriadic(baseColor);
    }
  }
}
