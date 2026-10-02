import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'double_edge_painter.dart';
import 'surface_mode.dart';

class CentrodeDoubleEdgeSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double cornerRadius;
  final BorderRadius? customBorderRadius;
  final double stepWidth;
  final bool enableDoubleEdge;
  final Color? backgroundColor;
  final Color? accentColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final CentrodeSurfaceMode? mode;
  final LiquidGlassFlex? touchFlex;
  final double distortion;
  final double distortionWidth;
  final double blur;

  const CentrodeDoubleEdgeSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.cornerRadius = 16.0,
    this.customBorderRadius,
    this.stepWidth = 0.8,
    this.enableDoubleEdge = true,
    this.backgroundColor,
    this.accentColor,
    this.gradient,
    this.boxShadow,
    this.mode,
    this.touchFlex = const LiquidGlassFlex.subtle(),
    this.distortion = 0.02,
    this.distortionWidth = 12.0,
    this.blur = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedMode = mode ?? CentrodeSurfaceScope.modeOf(context);
    final baseColor = backgroundColor ??
        (isDark ? const Color(0x18FFFFFF) : const Color(0x0AFFFFFF));

    final effectiveGradient = gradient ??
        CentrodeSurfaceScope.maybeOf(context)?.partialColorGradient ??
        (accentColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor!.withValues(alpha: isDark ? 0.18 : 0.10),
                  accentColor!.withValues(alpha: isDark ? 0.05 : 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              )
            : null);

    final resolvedBorderRadius = customBorderRadius ?? BorderRadius.circular(cornerRadius);

    final outerContainer = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: resolvedBorderRadius,
        boxShadow: boxShadow,
      ),
      child: resolvedMode == CentrodeSurfaceMode.quality
          ? _buildQualityGlass(context, isDark, baseColor, effectiveGradient, resolvedBorderRadius)
          : _buildPerformanceGlass(context, isDark, baseColor, effectiveGradient, resolvedBorderRadius),
    );

    return outerContainer;
  }

  Widget _buildQualityGlass(
    BuildContext context,
    bool isDark,
    Color baseColor,
    Gradient? effectiveGradient,
    BorderRadius resolvedBorderRadius,
  ) {
    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: LiquidGlassLens(
        touch: touchFlex != null
            ? LiquidGlassTouch(flex: touchFlex!)
            : null,
        style: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: customBorderRadius != null ? 0.0 : cornerRadius,
            borderWidth: 0.0,
          ),
          appearance: LiquidGlassAppearance(
            blur: LiquidGlassBlur(sigmaX: blur, sigmaY: blur),
            color: baseColor,
          ),
          refraction: LiquidGlassRefraction(
            distortion: distortion,
            distortionWidth: distortionWidth,
          ),
        ),
        child: Stack(
          fit: height != null ? StackFit.expand : StackFit.loose,
          children: [
            if (effectiveGradient != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: resolvedBorderRadius,
                      gradient: effectiveGradient,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
            if (enableDoubleEdge)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CentrodeDoubleEdgePainter(
                      cornerRadius: cornerRadius,
                      customBorderRadius: customBorderRadius,
                      stepWidth: stepWidth,
                      lightIntensity: isDark ? 1.15 : 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGlass(
    BuildContext context,
    bool isDark,
    Color baseColor,
    Gradient? effectiveGradient,
    BorderRadius resolvedBorderRadius,
  ) {
    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: baseColor,
          child: Stack(
            fit: height != null ? StackFit.expand : StackFit.loose,
            children: [
              if (effectiveGradient != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: resolvedBorderRadius,
                        gradient: effectiveGradient,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
              if (enableDoubleEdge)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CentrodeDoubleEdgePainter(
                        cornerRadius: cornerRadius,
                        customBorderRadius: customBorderRadius,
                        stepWidth: stepWidth,
                        lightIntensity: isDark ? 1.15 : 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
