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
  final double stepWidth;
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
    this.stepWidth = 2.0,
    this.backgroundColor,
    this.accentColor,
    this.gradient,
    this.boxShadow,
    this.mode,
    this.touchFlex = const LiquidGlassFlex.subtle(),
    this.distortion = 0.05,
    this.distortionWidth = 48.0,
    this.blur = 3.0,
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

    final outerContainer = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: boxShadow,
      ),
      child: resolvedMode == CentrodeSurfaceMode.quality
          ? _buildQualityGlass(context, isDark, baseColor, effectiveGradient)
          : _buildPerformanceGlass(context, isDark, baseColor, effectiveGradient),
    );

    return outerContainer;
  }

  Widget _buildQualityGlass(
    BuildContext context,
    bool isDark,
    Color baseColor,
    Gradient? effectiveGradient,
  ) {
    return LiquidGlassLens(
      touch: LiquidGlassTouch(
        flex: touchFlex ?? const LiquidGlassFlex.subtle(),
      ),
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
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
                    borderRadius: BorderRadius.circular(cornerRadius),
                    gradient: effectiveGradient,
                  ),
                ),
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CentrodeDoubleEdgePainter(
                  cornerRadius: cornerRadius,
                  stepWidth: stepWidth,
                  lightIntensity: isDark ? 1.15 : 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGlass(
    BuildContext context,
    bool isDark,
    Color baseColor,
    Gradient? effectiveGradient,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
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
                        borderRadius: BorderRadius.circular(cornerRadius),
                        gradient: effectiveGradient,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CentrodeDoubleEdgePainter(
                      cornerRadius: cornerRadius,
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
