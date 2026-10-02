import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'surfaces/double_edge_surface.dart';
import 'surfaces/surface_mode.dart';
import '../theme/design_tokens.dart';

class CentrodePanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final BorderRadius? customBorderRadius;
  final Color? color;
  final BoxShadow? shadow;
  final bool enableDoubleEdge;
  final double? stepWidth;
  final LiquidGlassFlex? touchFlex;
  final Border? border;
  final CentrodeSurfaceMode? mode;
  final Color? accentColor;
  final Gradient? gradient;
  final double? blur;
  final bool? enableBackdrop;
  final Duration? duration;
  final Curve? curve;
  final VoidCallback? onTap;

  const CentrodePanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.customBorderRadius,
    this.color,
    this.shadow,
    this.border,
    this.mode,
    this.enableDoubleEdge = true,
    this.stepWidth,
    this.touchFlex = const LiquidGlassFlex.subtle(),
    this.accentColor,
    this.gradient,
    this.blur,
    this.enableBackdrop,
    this.duration,
    this.curve,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ??
        (customBorderRadius != null
            ? [
                customBorderRadius!.topLeft.x,
                customBorderRadius!.topRight.x,
                customBorderRadius!.bottomLeft.x,
                customBorderRadius!.bottomRight.x,
              ].reduce((a, b) => a > b ? a : b)
            : UiRadius.card);

    final panel = CentrodeDoubleEdgeSurface(
      width: width,
      height: height,
      padding: padding,
      cornerRadius: radius,
      customBorderRadius: customBorderRadius,
      backgroundColor: color,
      boxShadow: shadow != null ? [shadow!] : null,
      mode: mode,
      enableDoubleEdge: enableDoubleEdge,
      stepWidth: stepWidth ?? 0.8,
      touchFlex: touchFlex,
      accentColor: accentColor,
      gradient: gradient,
      blur: blur ?? 3.0,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: panel,
      );
    }
    return panel;
  }
}

class CentrodeGroup extends StatelessWidget {
  final Widget child;
  const CentrodeGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

typedef GlassPanel = CentrodePanel;
typedef GlassGroup = CentrodeGroup;
