import 'package:flutter/material.dart';

class GlassPreset {
  final double? borderRadius;
  final double? blur;
  final Color? color;
  final BoxShadow? shadow;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassPreset({
    this.borderRadius,
    this.blur,
    this.color,
    this.shadow,
    this.padding,
    this.width,
    this.height,
  });
}

class GlassPresets {
  GlassPresets._();

  static GlassPreset toolbar(BuildContext context) => GlassPreset(
        borderRadius: 10,
        blur: 12,
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      );

  static GlassPreset submenu(BuildContext context, {required bool isRight}) =>
      GlassPreset(
        borderRadius: 8,
        blur: 10,
        color: Theme.of(context).cardColor.withValues(alpha: 0.92),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: Offset(isRight ? 2 : -2, 2),
        ),
      );

  static GlassPreset iconButton(BuildContext context) => GlassPreset(
        borderRadius: 14,
        width: 40,
        height: 40,
      );

  static GlassPreset tab(BuildContext context, {required bool isActive}) =>
      GlassPreset(
        borderRadius: 10,
        color: Theme.of(context)
            .cardColor
            .withValues(alpha: isActive ? 0.72 : 0.45),
        shadow: isActive
            ? BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            : null,
      );

  static GlassPreset ribbon(BuildContext context) => GlassPreset(
        borderRadius: 20,
        blur: 16,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      );
}
