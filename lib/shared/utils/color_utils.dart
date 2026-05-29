import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized utility for color luminance and contrast calculations.
class ColorUtils {
  /// Determines if a color is dark based on its relative luminance.
  static bool isDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// Determines if a color (represented as an ARGB integer) is dark.
  static bool isDarkInt(int colorValue) {
    return isDark(Color(colorValue));
  }

  /// Gets the appropriate high-contrast text color (black or white) for a given background color.
  /// Resolves curated aesthetics for default preset colors.
  static Color getContrastTextColor(Color backgroundColor) {
    return Color(getContrastTextColorInt(backgroundColor.toARGB32()));
  }

  /// Gets the appropriate high-contrast text color (represented as an ARGB integer) for a given background color value.
  static int getContrastTextColorInt(int bgColorVal) {
    switch (bgColorVal) {
      case 0xFFBBDEFB: return 0xFF0D47A1; // Light Blue -> Dark Blue text
      case 0xFFC8E6C9: return 0xFF1B5E20; // Light Green -> Dark Green text
      case 0xFFFFF9C4: return 0xFFF57F17; // Light Yellow -> Dark Yellow/Orange text
      case 0xFFE1BEE7: return 0xFF4A148C; // Lavender -> Dark Purple text
      case 0xFFF8BBD0: return 0xFF880E4F; // Rose -> Dark Pink/Rose text
      case 0xFFFFE0B2: return 0xFFE65100; // Orange -> Dark Orange text
      case 0xFFCFD8DC: return 0xFF263238; // Charcoal -> Dark Gray text
      case 0xFFEEEEEE: return 0xFF212121; // White/Gray -> Dark Charcoal text
    }
    return isDarkInt(bgColorVal) ? 0xFFFFFFFF : 0xFF000000;
  }

  /// Returns a suitable contrast stroke/border color for a given background color.
  static Color getContrastStrokeColor(Color backgroundColor) {
    return Color(getContrastStrokeColorInt(backgroundColor.toARGB32()));
  }

  /// Returns a suitable contrast stroke/border color (as ARGB integer) for a given background color value.
  static int getContrastStrokeColorInt(int bgColorVal) {
    switch (bgColorVal) {
      case 0xFFBBDEFB: return 0xFF1E88E5;
      case 0xFFC8E6C9: return 0xFF4CAF50;
      case 0xFFFFF9C4: return 0xFFFBC02D;
      case 0xFFE1BEE7: return 0xFF8E24AA;
      case 0xFFF8BBD0: return 0xFFD81B60;
      case 0xFFFFE0B2: return 0xFFFB8C00;
      case 0xFFCFD8DC: return 0xFF546E7A;
      case 0xFFEEEEEE: return 0xFF9E9E9E;
    }
    return isDarkInt(bgColorVal) ? 0x4DFFFFFF : 0x33000000; // 30% white vs 20% black
  }
}
