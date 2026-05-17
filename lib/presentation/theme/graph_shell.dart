import 'package:flutter/material.dart';

class GraphShell {
  final Color primaryColor;
  final Color scaffoldBackgroundColor;
  final Color cardColor;
  final Color dividerColor;
  final Color textColor;
  final String fontFamily;
  final double borderRadius;
  final bool useMaterial3;
  final Brightness brightness;

  const GraphShell({
    this.primaryColor = const Color(0xFF1976D2),
    this.scaffoldBackgroundColor = const Color(0xFFFFFFFF),
    this.cardColor = Colors.white,
    this.dividerColor = const Color(0xFFBDBDBD),
    this.textColor = const Color(0xFF212121),
    this.fontFamily = 'Roboto',
    this.borderRadius = 8.0,
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
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        surface: cardColor,
      ),
    );
  }
}
