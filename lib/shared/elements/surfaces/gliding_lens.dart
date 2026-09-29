import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'surface_mode.dart';
import 'double_edge_painter.dart';

class CentrodeGlidingLensPhysics {
  const CentrodeGlidingLensPhysics._();

  static double calculateStretch(double t) {
    if (t < 0.32) {
      return Curves.easeOutCubic.transform(t / 0.32);
    } else if (t <= 0.52) {
      return 1.0;
    } else if (t < 0.85) {
      final progress = Curves.easeOutBack.transform((t - 0.52) / 0.33);
      return (1.0 - progress).clamp(-0.08, 1.0);
    } else {
      return 0.0;
    }
  }

  static double calculatePosProgress(double t) {
    if (t < 0.06) {
      return 0.0;
    } else if (t < 0.75) {
      return Curves.easeInOutCubic.transform((t - 0.06) / 0.69);
    } else {
      return 1.0;
    }
  }

  static double calculateMorph(double t, double startMorph) {
    if (t < 0.25) {
      final progress = Curves.easeOutCubic.transform(t / 0.25);
      return startMorph + (1.0 - startMorph) * progress;
    } else if (t <= 0.60) {
      return 1.0;
    } else {
      final progress = Curves.easeInOut.transform((t - 0.60) / 0.40);
      return 1.0 - progress;
    }
  }
}

class CentrodeGlidingLens extends StatelessWidget {
  final Axis direction;
  final Rect activeRect;
  final double cornerRadius;
  final Color accentColor;
  final double morph;
  final bool isVisible;

  const CentrodeGlidingLens({
    super.key,
    required this.direction,
    required this.activeRect,
    required this.cornerRadius,
    required this.accentColor,
    this.morph = 1.0,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || activeRect.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceMode = CentrodeSurfaceScope.modeOf(context);
    final isQuality = surfaceMode == CentrodeSurfaceMode.quality;

    return Positioned.fromRect(
      rect: activeRect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isQuality && morph > 0.01)
            LiquidGlassBatch.exclude(
              child: LiquidGlassLens(
                honorBackdropAlpha: true,
                visibility: isVisible,
                touch: const LiquidGlassTouch(
                  flex: LiquidGlassFlex.pronounced(),
                ),
                style: LiquidGlassStyle(
                  shape: LiquidGlassShape.continuousRoundedRectangle(
                    cornerRadius: cornerRadius,
                    borderWidth: 1.0,
                    lightDirection: 35,
                    lightColor: Colors.white.withValues(alpha: 0.95),
                    lightIntensity: 1.25,
                  ),
                  appearance: LiquidGlassAppearance(
                    color: Colors.transparent,
                    blur: const LiquidGlassBlur(sigmaX: 0.0, sigmaY: 0.0),
                    shadow: LiquidGlassShadow(
                      color: accentColor.withValues(
                        alpha: isDark ? (0.35 * morph) : (0.25 * morph),
                      ),
                      blur: 10.0,
                      offset: const Offset(0, 2.0),
                    ),
                  ),
                  refraction: const LiquidGlassRefraction(
                    distortion: 0.24,
                    distortionWidth: 22.0,
                    magnification: 1.12,
                    chromaticAberration: 0.0,
                  ),
                ),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
                          accentColor.withValues(alpha: isDark ? 0.10 : 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: Opacity(
              opacity: (1.0 - morph).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(cornerRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.65),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.40 : 0.28),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isQuality || morph < 0.99)
            IgnorePointer(
              child: CustomPaint(
                painter: CentrodeDoubleEdgePainter(
                  cornerRadius: cornerRadius,
                  stepWidth: 1.2,
                  lightIntensity: isDark ? 1.0 : 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
