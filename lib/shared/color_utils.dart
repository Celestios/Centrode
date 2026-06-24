import 'package:flutter/material.dart';

Color getVerbColor(String? verb, ThemeData theme) {
  if (verb == null ||
      verb.isEmpty ||
      verb.trim().toLowerCase() == 'default') {
    return theme.colorScheme.primary;
  }
  final verbClean = verb.trim().toLowerCase();

  int hash = 0;
  for (int i = 0; i < verbClean.length; i++) {
    hash = verbClean.codeUnitAt(i) + ((hash << 5) - hash);
  }

  final double hue = (hash.abs() % 360).toDouble();

  final isDark = theme.brightness == Brightness.dark;
  final double saturation = isDark ? 0.75 : 0.65;
  final double lightness = isDark ? 0.65 : 0.45;

  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}
