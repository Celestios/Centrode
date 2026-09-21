// lib/features/graph/theme/graph_theme.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:centrode/presentation/theme/app_theme.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/theme/theme_surface_derivation.dart';

import 'package:centrode/src/rust/domain/types.dart' as frb;
import 'package:centrode/src/rust/domain/theme.dart' as frb;

class GraphTheme extends AppTheme {
  final String id;
  final String name;

  /// Used when loading a persisted theme from the database.
  const GraphTheme({
    required this.id,
    required this.name,
    super.primaryColor,
    super.secondaryColor,
    super.tertiaryColor,
    super.accentColor,
    super.canvasAccentColor,
    super.scaffoldBackgroundColor,
    super.cardColor,
    super.dividerColor,
    super.textColor,
    super.fontFamily,
    super.bodyFontSize,
    super.bodyFontWeight,
    super.bodyTextColor,
    super.borderRadius,
    super.appBarBackgroundColor,
    super.appBarForegroundColor,
    super.appBarElevation,
    super.appBarTitleFontSize,
    super.appBarTitleFontWeight,
    super.useMaterial3,
    super.brightness,
  });

  /// One‑time snapshot from the current global [ThemeData].
  factory GraphTheme.fromThemeData(
    ThemeData global, {
    String? name,
    String? id,
  }) {
    final ext = global.extension<CentrodeThemeExtension>();
    final palette = ext?.palette;
    final primary = palette?.tagColors[0] ?? global.colorScheme.primary;
    final secondary = palette?.tagColors[1] ?? global.colorScheme.secondary;
    final tertiary = palette?.tagColors[2] ?? global.colorScheme.tertiary;
    final accent = palette?.tagColors[3] ?? global.colorScheme.tertiary;
    final canvasAccent = palette?.tagColors[4] ?? global.colorScheme.primary;

    final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      anchors: [primary, secondary, tertiary, accent, canvasAccent],
      explicitBrightness: global.brightness,
    );

    return GraphTheme(
      id: id ?? const Uuid().v4(),
      name: name ?? 'graph-default',
      primaryColor: primary,
      secondaryColor: secondary,
      tertiaryColor: tertiary,
      accentColor: accent,
      canvasAccentColor: canvasAccent,
      scaffoldBackgroundColor: surfaces.scaffoldBackground,
      cardColor: surfaces.card,
      dividerColor: surfaces.divider,
      textColor: surfaces.text,
      fontFamily: global.textTheme.bodyLarge?.fontFamily ?? 'Roboto',
      bodyFontSize: global.textTheme.bodyLarge?.fontSize ?? 14,
      bodyFontWeight:
          global.textTheme.bodyLarge?.fontWeight ?? FontWeight.normal,
      bodyTextColor: surfaces.text,
      borderRadius: () {
        if (global.cardTheme.shape is RoundedRectangleBorder) {
          final shape = global.cardTheme.shape as RoundedRectangleBorder;
          final geometry = shape.borderRadius;
          if (geometry is BorderRadius) return geometry.topLeft.x;
        }
        return 8.0;
      }(),
      appBarBackgroundColor: surfaces.appBarBackground,
      appBarForegroundColor: surfaces.appBarForeground,
      appBarElevation: global.appBarTheme.elevation ?? 2.0,
      appBarTitleFontSize: global.appBarTheme.titleTextStyle?.fontSize ?? 20,
      appBarTitleFontWeight:
          global.appBarTheme.titleTextStyle?.fontWeight ?? FontWeight.w600,
      useMaterial3: global.useMaterial3,
      brightness: surfaces.brightness,
    );
  }

  (String, frb.ThemeFields) toRust() {
    return (
      id, // key
      frb.ThemeFields(
        name: name,
        primaryColor: primaryColor.toARGB32(),
        secondaryColor: secondaryColor.toARGB32(),
        tertiaryColor: tertiaryColor.toARGB32(),
        accentColor: accentColor.toARGB32(),
        canvasAccentColor: canvasAccentColor.toARGB32(),
        fontFamily: fontFamily,
        bodyFontSize: bodyFontSize,
        bodyFontWeight: frb.FontWeight(
          field0: AppTheme.fontWeightToIndex(bodyFontWeight),
        ),
        borderRadius: borderRadius,
        appBarElevation: appBarElevation,
        appBarTitleFontSize: appBarTitleFontSize,
        appBarTitleFontWeight: frb.FontWeight(
          field0: AppTheme.fontWeightToIndex(appBarTitleFontWeight),
        ),
        useMaterial3: useMaterial3,
      ),
    );
  }

  factory GraphTheme.fromRust(frb.MapTheme theme) {
    final f = theme.fields;
    final primary = Color(f.primaryColor);
    final secondary = Color(f.secondaryColor);
    final tertiary = Color(f.tertiaryColor);
    final accent = Color(f.accentColor);
    final canvasAccent = Color(f.canvasAccentColor);

    final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      anchors: [primary, secondary, tertiary, accent, canvasAccent],
    );

    return GraphTheme(
      id: theme.key.key.uuid,
      name: f.name,
      primaryColor: primary,
      secondaryColor: secondary,
      tertiaryColor: tertiary,
      accentColor: accent,
      canvasAccentColor: canvasAccent,
      scaffoldBackgroundColor: surfaces.scaffoldBackground,
      cardColor: surfaces.card,
      dividerColor: surfaces.divider,
      textColor: surfaces.text,
      fontFamily: f.fontFamily,
      bodyFontSize: f.bodyFontSize,
      bodyFontWeight: AppTheme.fontWeights[f.bodyFontWeight.field0.clamp(0, 8)],
      bodyTextColor: surfaces.text,
      borderRadius: f.borderRadius,
      appBarBackgroundColor: surfaces.appBarBackground,
      appBarForegroundColor: surfaces.appBarForeground,
      appBarElevation: f.appBarElevation,
      appBarTitleFontSize: f.appBarTitleFontSize,
      appBarTitleFontWeight:
          AppTheme.fontWeights[f.appBarTitleFontWeight.field0.clamp(0, 8)],
      useMaterial3: f.useMaterial3,
      brightness: surfaces.brightness,
    );
  }
}
