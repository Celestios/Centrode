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
      'bodyFontWeight': fontWeightToIndex(bodyFontWeight),
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
    Color parseColor(dynamic value, {String? fieldName}) {
      if (value == null) {
        throw FormatException('Missing required theme color: $fieldName');
      }
      if (value is int) return Color(value);
      if (value is String) {
        final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
      throw FormatException('Invalid color value for $fieldName: $value');
    }

    Color? parseColorOptional(dynamic value) {
      if (value == null) return null;
      if (value is int) return Color(value);
      if (value is String) {
        final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
      return null;
    }

    FontWeight parseWeight(dynamic value, {FontWeight? fallback}) {
      if (value == null) {
        if (fallback != null) return fallback;
        throw FormatException('Missing required font weight');
      }
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
            if (fallback != null) return fallback;
            throw FormatException('Invalid font weight: $value');
        }
      }
      throw FormatException('Invalid font weight type: $value');
    }

    final brightnessStr = map['brightness'] as String?;
    final brightness = brightnessStr == 'dark'
        ? Brightness.dark
        : Brightness.light;

    return AppTheme(
      primaryColor: parseColor(
        map['primaryColor'],
        fieldName: 'primaryColor',
      ),
      secondaryColor: parseColor(
        map['secondaryColor'],
        fieldName: 'secondaryColor',
      ),
      accentColor: parseColor(
        map['accentColor'],
        fieldName: 'accentColor',
      ),
      canvasAccentColor: parseColorOptional(map['canvasAccentColor']) ?? parseColor(
        map['primaryColor'],
        fieldName: 'primaryColor',
      ),
      scaffoldBackgroundColor: parseColor(
        map['scaffoldBackgroundColor'],
        fieldName: 'scaffoldBackgroundColor',
      ),
      cardColor: parseColor(map['cardColor'], fieldName: 'cardColor'),
      dividerColor: parseColor(
        map['dividerColor'],
        fieldName: 'dividerColor',
      ),
      textColor: parseColor(
        map['textColor'],
        fieldName: 'textColor',
      ),
      fontFamily: map['fontFamily'] as String? ?? 'Roboto',
      bodyFontSize: (map['bodyFontSize'] as num?)?.toDouble() ?? 14.0,
      bodyFontWeight: parseWeight(map['bodyFontWeight'], fallback: FontWeight.normal),
      bodyTextColor: parseColor(
        map['bodyTextColor'],
        fieldName: 'bodyTextColor',
      ),
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
      appBarBackgroundColor: parseColor(
        map['appBarBackgroundColor'],
        fieldName: 'appBarBackgroundColor',
      ),
      appBarForegroundColor: parseColor(
        map['appBarForegroundColor'],
        fieldName: 'appBarForegroundColor',
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
