import 'package:centrode/shared/theme/design_tokens.dart';
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
        borderRadius: UiRadius.card,
        blur: 12,
        color: Theme.of(context).cardColor.withValues(alpha: UiAlpha.glassBody),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: UiAlpha.borderSubtle),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      );

  static GlassPreset submenu(BuildContext context, {required bool isRight}) =>
      GlassPreset(
        borderRadius: UiRadius.card,
        blur: 10,
        color: Theme.of(context).cardColor.withValues(alpha: UiAlpha.glassBody),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: UiAlpha.borderSubtle),
          blurRadius: 8,
          offset: Offset(isRight ? 2 : -2, 2),
        ),
      );

  static GlassPreset iconButton(BuildContext context) => GlassPreset(
        borderRadius: UiRadius.panel,
        width: 40,
        height: UiControlSize.tile,
      );

  static GlassPreset tab(BuildContext context, {required bool isActive}) =>
      GlassPreset(
        borderRadius: UiRadius.card,
        color: Theme.of(context)
            .cardColor
            .withValues(alpha: isActive ? UiAlpha.muted : UiAlpha.half),
        shadow: isActive
            ? BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: UiAlpha.subtle),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            : null,
      );

  static GlassPreset ribbon(BuildContext context) => GlassPreset(
        borderRadius: UiRadius.panel,
        blur: 16,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: UiAlpha.borderSubtle),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      );
}
