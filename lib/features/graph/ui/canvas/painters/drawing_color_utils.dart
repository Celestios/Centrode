import 'package:flutter/material.dart';

abstract class DrawingColorUtils {
  /// Parses a hex color string into a Flutter [Color].
  static Color parseColor(String hex, {Color fallback = const Color(0xFF00E5FF)}) {
    try {
      final clean = hex.replaceFirst('#', '').replaceFirst('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Resolves the final color considering brush type (e.g. highlighter alpha).
  static Color resolveBrushColor(String hexColor, String brushType) {
    var color = parseColor(hexColor);
    if (brushType == 'highlighter') {
      color = color.withValues(alpha: 0.4);
    }
    return color;
  }
}
