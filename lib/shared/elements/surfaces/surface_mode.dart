import 'package:flutter/material.dart';

enum CentrodeSurfaceMode {
  quality,
  performance,
}

class CentrodeSurfaceScope extends InheritedWidget {
  final CentrodeSurfaceMode mode;
  final bool isDark;
  final Color? accentColor;
  final Gradient? partialColorGradient;

  const CentrodeSurfaceScope({
    super.key,
    required this.mode,
    required this.isDark,
    this.accentColor,
    this.partialColorGradient,
    required super.child,
  });

  static CentrodeSurfaceScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CentrodeSurfaceScope>();
  }

  static CentrodeSurfaceMode modeOf(BuildContext context) {
    final scope = maybeOf(context);
    return scope?.mode ?? CentrodeSurfaceMode.quality;
  }

  @override
  bool updateShouldNotify(CentrodeSurfaceScope oldWidget) {
    return oldWidget.mode != mode ||
        oldWidget.isDark != isDark ||
        oldWidget.accentColor != accentColor ||
        oldWidget.partialColorGradient != partialColorGradient;
  }
}
