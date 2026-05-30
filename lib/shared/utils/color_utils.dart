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
      case 0xFF818CF8: return 0xFF312E81; // Premium Indigo -> Deep Indigo text
      case 0xFF34D399: return 0xFF064E3B; // Premium Mint -> Deep Emerald text
      case 0xFFFBBF24: return 0xFF78350F; // Premium Amber -> Deep Amber text
      case 0xFFC084FC: return 0xFF581C87; // Premium Lavender -> Deep Purple text
      case 0xFFF472B6: return 0xFF831843; // Premium Rose -> Deep Pink text
      case 0xFFFB923C: return 0xFF7C2D12; // Premium Orange -> Deep Orange text
      case 0xFF94A3B8: return 0xFF0F172A; // Premium Slate -> Deep Slate text
      case 0xFFE2E8F0: return 0xFF1E293B; // Premium Slate White -> Slate Text
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
      case 0xFF818CF8: return 0xFF4F46E5;
      case 0xFF34D399: return 0xFF059669;
      case 0xFFFBBF24: return 0xFFD97706;
      case 0xFFC084FC: return 0xFF9333EA;
      case 0xFFF472B6: return 0xFFDB2777;
      case 0xFFFB923C: return 0xFFEA580C;
      case 0xFF94A3B8: return 0xFF475569;
      case 0xFFE2E8F0: return 0xFFCBD5E1;
    }
    return isDarkInt(bgColorVal) ? 0x4DFFFFFF : 0x33000000; // 30% white vs 20% black
  }
}
