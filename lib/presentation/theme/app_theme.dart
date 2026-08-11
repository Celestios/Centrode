// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const List<FontWeight> fontWeights = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];

  static int fontWeightToIndex(FontWeight weight) {
    return (weight.value ~/ 100) - 1;
  }

  // ── Core palette ──────────────────────────────
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color canvasAccentColor;
  final Color scaffoldBackgroundColor;
  final Color cardColor;
  final Color dividerColor;
  final Color textColor;

  // ── Typography ────────────────────────────────
  final String fontFamily;
  final double bodyFontSize;
  final FontWeight bodyFontWeight;
  final Color bodyTextColor;

  // ── Shape ─────────────────────────────────────
  final double borderRadius;

  // ── AppBar ────────────────────────────────────
  final Color appBarBackgroundColor;
  final Color appBarForegroundColor;
  final double appBarElevation;
  final double appBarTitleFontSize;
  final FontWeight appBarTitleFontWeight;

  // ── Material 3 & Brightness ───────────────────
  final bool useMaterial3;
  final Brightness brightness;

  Color get hoverAccentColor =>
      HSLColor.fromColor(canvasAccentColor)
          .withLightness(
            (HSLColor.fromColor(canvasAccentColor).lightness + 0.15)
                .clamp(0.0, 1.0),
          )
          .toColor();

  const AppTheme({
    // palette
    this.primaryColor = const Color(0xFF1976D2),
    this.secondaryColor = const Color(0xFF47A2FF),
    this.accentColor = const Color(0xFFFF4081),
    this.canvasAccentColor = const Color(0xFF2196F3),
    this.scaffoldBackgroundColor = const Color(0xFFF5F5F5),
    this.cardColor = Colors.white,
    this.dividerColor = const Color(0xFFBDBDBD),
    this.textColor = const Color(0xFF212121),
    // typography
    this.fontFamily = 'Roboto',
    this.bodyFontSize = 14.0,
    this.bodyFontWeight = FontWeight.normal,
    this.bodyTextColor = const Color(0xFF212121),
    // shape
    this.borderRadius = 8.0,
    // appbar
    this.appBarBackgroundColor = const Color(0xFF1976D2),
    this.appBarForegroundColor = Colors.white,
    this.appBarElevation = 0.0,
    this.appBarTitleFontSize = 20.0,
    this.appBarTitleFontWeight = FontWeight.w600,
    // material
    this.useMaterial3 = true,
    this.brightness = Brightness.light,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      fontFamily: fontFamily,

      // ── Cards ──
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: appBarElevation,
        titleTextStyle: TextStyle(
          color: appBarForegroundColor,
          fontFamily: fontFamily,
          fontSize: appBarTitleFontSize,
          fontWeight: appBarTitleFontWeight,
        ),
      ),

      // ── Text ──
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: bodyTextColor,
          fontFamily: fontFamily,
          fontSize: bodyFontSize,
          fontWeight: bodyFontWeight,
        ),
        bodyMedium: TextStyle(
          color: bodyTextColor,
          fontFamily: fontFamily,
          fontSize: bodyFontSize,
          fontWeight: bodyFontWeight,
        ),
      ),

      // ── ColorScheme ──
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        brightness: brightness,
        surface: cardColor,
      ),
    );
  }

  // ── Persistence ───────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'canvasAccentColor': canvasAccentColor.toARGB32(),
      'scaffoldBackgroundColor': scaffoldBackgroundColor.toARGB32(),
      'cardColor': cardColor.toARGB32(),
      'dividerColor': dividerColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'fontFamily': fontFamily,
      'bodyFontSize': bodyFontSize,
      'bodyFontWeight': fontWeightToIndex(bodyFontWeight), // save as int
      'bodyTextColor': bodyTextColor.toARGB32(),
      'borderRadius': borderRadius,
      'appBarBackgroundColor': appBarBackgroundColor.toARGB32(),
      'appBarForegroundColor': appBarForegroundColor.toARGB32(),
      'appBarElevation': appBarElevation,
      'appBarTitleFontSize': appBarTitleFontSize,
      'appBarTitleFontWeight': fontWeightToIndex(appBarTitleFontWeight),
      'useMaterial3': useMaterial3,
      'brightness': brightness.name,
    };
  }

  factory AppTheme.fromMap(Map<String, dynamic> map) {
    // Helper: parse colour from int or hex string
    Color parseColor(dynamic value, {required Color fallback}) {
      if (value == null) return fallback;
      if (value is int) return Color(value);
      if (value is String) {
        final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
      return fallback;
    }

    FontWeight parseWeight(
      dynamic value, {
      FontWeight fallback = FontWeight.normal,
    }) {
      if (value == null) return fallback;
      if (value is int) {
        return fontWeights[value.clamp(0, fontWeights.length - 1)];
      }
      if (value is String) {
        switch (value.toLowerCase()) {
          case 'w100':
            return FontWeight.w100;
          case 'w200':
            return FontWeight.w200;
          case 'w300':
            return FontWeight.w300;
          case 'w400':
          case 'normal':
            return FontWeight.w400;
          case 'w500':
            return FontWeight.w500;
          case 'w600':
            return FontWeight.w600;
          case 'w700':
          case 'bold':
            return FontWeight.w700;
          case 'w800':
            return FontWeight.w800;
          case 'w900':
            return FontWeight.w900;
          default:
            return fallback;
        }
      }
      return fallback;
    }

    final brightnessStr = map['brightness'] as String?;
    final brightness = brightnessStr == 'dark'
        ? Brightness.dark
        : Brightness.light;

    return AppTheme(
      primaryColor: parseColor(
        map['primaryColor'],
        fallback: const Color(0xFF1976D2),
      ),
      secondaryColor: parseColor(
        map['secondaryColor'],
        fallback: const Color(0xFF47A2FF),
      ),
      accentColor: parseColor(
        map['accentColor'],
        fallback: const Color(0xFFFF4081),
      ),
      canvasAccentColor: parseColor(
        map['canvasAccentColor'],
        fallback: const Color(0xFF2196F3),
      ),
      scaffoldBackgroundColor: parseColor(
        map['scaffoldBackgroundColor'],
        fallback: const Color(0xFFF5F5F5),
      ),
      cardColor: parseColor(map['cardColor'], fallback: Colors.white),
      dividerColor: parseColor(
        map['dividerColor'],
        fallback: const Color(0xFFBDBDBD),
      ),
      textColor: parseColor(
        map['textColor'],
        fallback: const Color(0xFF212121),
      ),
      fontFamily: map['fontFamily'] as String? ?? 'Roboto',
      bodyFontSize: (map['bodyFontSize'] as num?)?.toDouble() ?? 14.0,
      bodyFontWeight: parseWeight(map['bodyFontWeight']),
      bodyTextColor: parseColor(
        map['bodyTextColor'],
        fallback: const Color(0xFF212121),
      ),
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
      appBarBackgroundColor: parseColor(
        map['appBarBackgroundColor'],
        fallback: const Color(0xFF1976D2),
      ),
      appBarForegroundColor: parseColor(
        map['appBarForegroundColor'],
        fallback: Colors.white,
      ),
      appBarElevation: (map['appBarElevation'] as num?)?.toDouble() ?? 0.0,
      appBarTitleFontSize:
          (map['appBarTitleFontSize'] as num?)?.toDouble() ?? 20.0,
      appBarTitleFontWeight: parseWeight(
        map['appBarTitleFontWeight'],
        fallback: FontWeight.w600,
      ),
      useMaterial3: map['useMaterial3'] as bool? ?? true,
      brightness: brightness,
    );
  }
}
