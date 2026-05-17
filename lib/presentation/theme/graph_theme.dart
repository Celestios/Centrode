// lib/features/graph/theme/graph_theme.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/presentation/theme/app_theme.dart';

import 'package:mycelium/src/rust/domain/theme.dart' as frb;

class GraphTheme extends AppTheme {
  final String id;
  final String name;

  /// Used when loading a persisted theme from the database.
  const GraphTheme({
    required this.id,
    required this.name,
    super.primaryColor,
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
  factory GraphTheme.fromThemeData(ThemeData global, {String? name}) {
    return GraphTheme(
      id: const Uuid().v4(),
      name: name ?? 'graph-default',
      primaryColor: global.colorScheme.primary,
      scaffoldBackgroundColor: global.scaffoldBackgroundColor,
      cardColor: global.cardColor,
      dividerColor: global.dividerColor,
      textColor: global.textTheme.bodyLarge?.color ?? Colors.black,
      fontFamily: global.textTheme.bodyLarge?.fontFamily ?? 'Roboto',
      bodyFontSize: global.textTheme.bodyLarge?.fontSize ?? 14,
      bodyFontWeight:
          global.textTheme.bodyLarge?.fontWeight ?? FontWeight.normal,
      bodyTextColor: global.textTheme.bodyLarge?.color ?? Colors.black,
      borderRadius: () {
        if (global.cardTheme.shape is RoundedRectangleBorder) {
          final shape = global.cardTheme.shape as RoundedRectangleBorder;
          final geometry = shape.borderRadius;
          if (geometry is BorderRadius) return geometry.topLeft.x;
        }
        return 8.0;
      }(),
      appBarBackgroundColor:
          global.appBarTheme.backgroundColor ?? global.colorScheme.primary,
      appBarForegroundColor: global.appBarTheme.foregroundColor ?? Colors.white,
      appBarElevation: global.appBarTheme.elevation ?? 0,
      appBarTitleFontSize: global.appBarTheme.titleTextStyle?.fontSize ?? 20,
      appBarTitleFontWeight:
          global.appBarTheme.titleTextStyle?.fontWeight ?? FontWeight.w600,
      useMaterial3: global.useMaterial3,
      brightness: global.brightness,
    );
  }

  (String, frb.ThemeFields) toRust() {
    return (
      id, // key
      frb.ThemeFields(
        name: name,
        primaryColor: primaryColor.toARGB32(),
        scaffoldBackgroundColor: scaffoldBackgroundColor.toARGB32(),
        cardColor: cardColor.toARGB32(),
        dividerColor: dividerColor.toARGB32(),
        textColor: textColor.toARGB32(),
        fontFamily: fontFamily,
        bodyFontSize: bodyFontSize,
        bodyFontWeight: frb.FontWeight(field0: bodyFontWeight.index),
        bodyTextColor: bodyTextColor.toARGB32(),
        borderRadius: borderRadius,
        appBarBackgroundColor: appBarBackgroundColor.toARGB32(),
        appBarForegroundColor: appBarForegroundColor.toARGB32(),
        appBarElevation: appBarElevation,
        appBarTitleFontSize: appBarTitleFontSize,
        appBarTitleFontWeight: frb.FontWeight(
          field0: appBarTitleFontWeight.index,
        ),
        useMaterial3: useMaterial3,
        brightness: brightness == Brightness.dark
            ? frb.ThemeBrightness.dark
            : frb.ThemeBrightness.light,
      ),
    );
  }

  factory GraphTheme.fromRust(frb.Theme theme) {
    final f = theme.fields;
    return GraphTheme(
      id: theme.key,
      name: f.name,
      primaryColor: Color(f.primaryColor),
      scaffoldBackgroundColor: Color(f.scaffoldBackgroundColor),
      cardColor: Color(f.cardColor),
      dividerColor: Color(f.dividerColor),
      textColor: Color(f.textColor),
      fontFamily: f.fontFamily,
      bodyFontSize: f.bodyFontSize,
      bodyFontWeight: FontWeight.values[f.bodyFontWeight.field0],
      bodyTextColor: Color(f.bodyTextColor),
      borderRadius: f.borderRadius,
      appBarBackgroundColor: Color(f.appBarBackgroundColor),
      appBarForegroundColor: Color(f.appBarForegroundColor),
      appBarElevation: f.appBarElevation,
      appBarTitleFontSize: f.appBarTitleFontSize,
      appBarTitleFontWeight: FontWeight.values[f.appBarTitleFontWeight.field0],
      useMaterial3: f.useMaterial3,
      brightness: f.brightness == frb.ThemeBrightness.dark
          ? Brightness.dark
          : Brightness.light,
    );
  }
}
