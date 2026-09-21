// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/theme/theme_surface_derivation.dart';

class AppTheme implements ThemeAnchorPaletteSource {
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
  @override
  final Color primaryColor;
  @override
  final Color secondaryColor;
  @override
  final Color tertiaryColor;
  @override
  final Color accentColor;
  @override
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
  @override
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
    this.primaryColor = const Color(0xFF818CF8),
    this.secondaryColor = const Color(0xFF101216),
    this.tertiaryColor = const Color(0xFFD4B400),
    this.accentColor = const Color(0xFFF43F5E),
    this.canvasAccentColor = const Color(0xFF06B6D4),
    this.scaffoldBackgroundColor = const Color(0xFF101216),
    this.cardColor = const Color(0xFF16181E),
    this.dividerColor = const Color(0x1AFFFFFF),
    this.textColor = const Color(0xFFF8FAFC),
    // typography
    this.fontFamily = 'Roboto',
    this.bodyFontSize = 14.0,
    this.bodyFontWeight = FontWeight.normal,
    this.bodyTextColor = const Color(0xFFF8FAFC),
    // shape
    this.borderRadius = 8.0,
    // appbar
    this.appBarBackgroundColor = const Color(0xFF101216),
    this.appBarForegroundColor = const Color(0xFFFFFFFF),
    this.appBarElevation = 2.0,
    this.appBarTitleFontSize = 20.0,
    this.appBarTitleFontWeight = FontWeight.w600,
    // material
    this.useMaterial3 = true,
    this.brightness = Brightness.dark,
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
      extensions: [
        CentrodeThemeExtension(
          palette: CentrodeDerivedPalette.fromSource(this),
        ),
      ],

      // ── Icons ──
      iconTheme: IconThemeData(
        color: textColor.withValues(alpha: 0.75),
      ),

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
        tertiary: tertiaryColor,
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
      'tertiaryColor': tertiaryColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'canvasAccentColor': canvasAccentColor.toARGB32(),
      'fontFamily': fontFamily,
      'bodyFontSize': bodyFontSize,
      'bodyFontWeight': fontWeightToIndex(bodyFontWeight),
      'borderRadius': borderRadius,
      'appBarElevation': appBarElevation,
      'appBarTitleFontSize': appBarTitleFontSize,
      'appBarTitleFontWeight': fontWeightToIndex(appBarTitleFontWeight),
      'useMaterial3': useMaterial3,
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

    final primaryColor = parseColor(
      map['primaryColor'],
      fieldName: 'primaryColor',
    );
    final secondaryColor = parseColor(
      map['secondaryColor'],
      fieldName: 'secondaryColor',
    );
    final tertiaryColor = parseColor(
      map['tertiaryColor'],
      fieldName: 'tertiaryColor',
    );
    final accentColor = parseColor(
      map['accentColor'],
      fieldName: 'accentColor',
    );
    final canvasAccentColor = parseColor(
      map['canvasAccentColor'],
      fieldName: 'canvasAccentColor',
    );

    // Intelligently derive brightness, surfaces, borders, and text from the 5 anchors
    final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      anchors: [primaryColor, secondaryColor, tertiaryColor, accentColor, canvasAccentColor],
    );

    return AppTheme(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      accentColor: accentColor,
      canvasAccentColor: canvasAccentColor,
      scaffoldBackgroundColor: surfaces.scaffoldBackground,
      cardColor: surfaces.card,
      dividerColor: surfaces.divider,
      textColor: surfaces.text,
      bodyTextColor: surfaces.text,
      fontFamily: map['fontFamily'] as String? ?? 'Roboto',
      bodyFontSize: (map['bodyFontSize'] as num?)?.toDouble() ?? 14.0,
      bodyFontWeight: parseWeight(map['bodyFontWeight'], fallback: FontWeight.normal),
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
      appBarBackgroundColor: surfaces.appBarBackground,
      appBarForegroundColor: surfaces.appBarForeground,
      appBarElevation: (map['appBarElevation'] as num?)?.toDouble() ?? 2.0,
      appBarTitleFontSize:
          (map['appBarTitleFontSize'] as num?)?.toDouble() ?? 20.0,
      appBarTitleFontWeight: parseWeight(
        map['appBarTitleFontWeight'],
        fallback: FontWeight.w600,
      ),
      useMaterial3: map['useMaterial3'] as bool? ?? true,
      brightness: surfaces.brightness,
    );
  }
}
