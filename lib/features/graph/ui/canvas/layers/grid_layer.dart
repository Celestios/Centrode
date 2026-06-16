import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../engine/config.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/shared/utils/color_utils.dart';

class GridLayer extends StatefulWidget {
  final ViewportStateGrid viewportState;
  final ValueNotifier<Offset?> mousePositionNotifier;

  const GridLayer({
    super.key,
    required this.viewportState,
    required this.mousePositionNotifier,
  });

  @override
  State<GridLayer> createState() => _GridLayerState();
}

class _GridLayerState extends State<GridLayer>
    with SingleTickerProviderStateMixin {
  Offset? _visualGlowPos;
  double _glowOpacity = 0.0;
  Ticker? _ticker;
  Offset _velocity = Offset.zero;
  Duration _lastFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.mousePositionNotifier.addListener(_onMouseMoved);
  }

  @override
  void didUpdateWidget(covariant GridLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mousePositionNotifier != widget.mousePositionNotifier) {
      oldWidget.mousePositionNotifier.removeListener(_onMouseMoved);
      widget.mousePositionNotifier.addListener(_onMouseMoved);
    }
  }

  @override
  void dispose() {
    widget.mousePositionNotifier.removeListener(_onMouseMoved);
    _ticker?.dispose();
    super.dispose();
  }

  void _onMouseMoved() {
    final mousePos = widget.mousePositionNotifier.value;
    if (mousePos != null && !_ticker!.isActive) {
      _lastFrameTime = Duration.zero;
      _ticker!.start();
    } else if (mousePos == null && !_ticker!.isActive && _glowOpacity > 0.0) {
      _lastFrameTime = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    // Calculate dt in seconds, clamped to protect against extreme spikes
    double dt = 0.016; // Fallback
    if (_lastFrameTime != Duration.zero) {
      dt = (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    }
    _lastFrameTime = elapsed;
    dt = dt.clamp(0.008, 0.033);

    final physicalMousePos = widget.mousePositionNotifier.value;

    if (physicalMousePos == null) {
      // Smoothly decay opacity and drag visual position to a stop
      setState(() {
        _glowOpacity = (_glowOpacity - 4.0 * dt).clamp(0.0, 1.0);
        _velocity = _velocity * (1.0 - 10.0 * dt).clamp(0.0, 1.0);

        if (_glowOpacity == 0.0) {
          _visualGlowPos = null;
          _velocity = Offset.zero;
          _ticker!.stop();
        }
      });
    } else {
      // Smoothly fade in and track position using distance-dependent spring-like dynamics
      setState(() {
        _glowOpacity = (_glowOpacity + 6.0 * dt).clamp(0.0, 1.0);

        if (_visualGlowPos == null) {
          _visualGlowPos = physicalMousePos;
          _velocity = Offset.zero;
        } else {
          final displacement = physicalMousePos - _visualGlowPos!;
          final dist = displacement.distance;

          // Distance-dependent easing: soft at close range, tighter far away
          final double baseEase = 0.05;
          final double maxAdditionalEase = 0.09;
          final double halfSatDistance = 150.0;
          final double easeFactor =
              baseEase + maxAdditionalEase * (dist / (dist + halfSatDistance));

          // Calculate step, making it frame-rate independent
          final double step = (easeFactor * 60.0 * dt).clamp(0.0, 1.0);

          if (dist < 0.05 && _glowOpacity >= 1.0) {
            _visualGlowPos = physicalMousePos;
            _velocity = Offset.zero;
            _ticker!.stop();
          } else {
            // Interpolate visual position
            _visualGlowPos = Offset.lerp(
              _visualGlowPos,
              physicalMousePos,
              step,
            );

            // Save the displacement/lag vector to pass to the painter
            _velocity = physicalMousePos - _visualGlowPos!;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = ColorUtils.isDark(backgroundColor);

    final Color dotColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final Color glowColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF1E1E1E).withValues(alpha: 0.85);

    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: widget.viewportState.viewportSize,
            painter: _StaticGridPainter(
              visibleRect: widget.viewportState.visibleRect,
              scale: widget.viewportState.scale,
              backgroundColor: backgroundColor,
              dotColor: dotColor,
            ),
          ),
        ),
        if (_visualGlowPos != null && _glowOpacity > 0.0)
          RepaintBoundary(
            child: CustomPaint(
              size: widget.viewportState.viewportSize,
              painter: _GlowGridPainter(
                visibleRect: widget.viewportState.visibleRect,
                scale: widget.viewportState.scale,
                dotColor: dotColor,
                glowColor: glowColor,
                visualGlowPos: _visualGlowPos,
                glowOpacity: _glowOpacity,
                velocity: _velocity,
              ),
              willChange: true, // high-frequency updates during gestures
            ),
          ),
      ],
    );
  }
}

class _StaticGridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Color backgroundColor;
  final Color dotColor;

  _StaticGridPainter({
    required this.visibleRect,
    required this.scale,
    required this.backgroundColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    canvas.drawRect(visibleRect, Paint()..color = backgroundColor);

    final double effectiveGridSize = calculateEffectiveGridSize(scale);

    // Find starting points within the visible rectangle
    final double startX =
        (visibleRect.left / effectiveGridSize).floor() * effectiveGridSize;
    final double startY =
        (visibleRect.top / effectiveGridSize).floor() * effectiveGridSize;

    // Collect all grid dot positions (in logical space)
    final List<Offset> points = [];
    for (
      double x = startX;
      x <= visibleRect.right + effectiveGridSize;
      x += effectiveGridSize
    ) {
      for (
        double y = startY;
        y <= visibleRect.bottom + effectiveGridSize;
        y += effectiveGridSize
      ) {
        points.add(Offset(x, y));
      }
    }

    // Render dots with constant screen-space size
    final paint = Paint()
      ..color = dotColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (AppConfig.grid.dotRadius * 2) / scale;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _StaticGridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor;
  }
}

class _GlowGridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Color dotColor;
  final Color glowColor;
  final Offset? visualGlowPos;
  final double glowOpacity;
  final Offset velocity;

  _GlowGridPainter({
    required this.visibleRect,
    required this.scale,
    required this.dotColor,
    required this.glowColor,
    required this.visualGlowPos,
    required this.glowOpacity,
    required this.velocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPosLocal = visualGlowPos;
    if (glowPosLocal == null || glowOpacity <= 0.0) return;

    final double effectiveGridSize = calculateEffectiveGridSize(scale);

    // Calculate logical coordinates for the mouse position
    final Offset glowPos = visibleRect.topLeft + (glowPosLocal / scale);

    // The velocity parameter represents the lag/displacement vector in logical space
    final Offset displacementLogical = velocity / scale;
    final double lagDistance = displacementLogical.distance;

    const double baseInfluenceRadius = 160.0;

    double a = baseInfluenceRadius;
    double b = baseInfluenceRadius;
    double cosAngle = 1.0;
    double sinAngle = 0.0;

    if (lagDistance > 2.0) {
      // Saturation-based stretch/compression to prevent the ellipse from collapsing into a line
      final double saturation = lagDistance / (lagDistance + 60.0);

      const double maxStretch = 120.0;
      const double maxCompress = 40.0;

      a = baseInfluenceRadius + maxStretch * saturation;
      b = baseInfluenceRadius - maxCompress * saturation;

      // Direction vector aligned with the displacement (motion tail)
      final Offset dir = displacementLogical / lagDistance;
      cosAngle = dir.dx;
      sinAngle = dir.dy;
    }

    // Find local bounding box of the ellipse to restrict calculation loop
    final double maxDim = a > b ? a : b;
    final double minGlowX =
        ((glowPos.dx - maxDim) / effectiveGridSize).floor() * effectiveGridSize;
    final double maxGlowX =
        ((glowPos.dx + maxDim) / effectiveGridSize).ceil() * effectiveGridSize;
    final double minGlowY =
        ((glowPos.dy - maxDim) / effectiveGridSize).floor() * effectiveGridSize;
    final double maxGlowY =
        ((glowPos.dy + maxDim) / effectiveGridSize).ceil() * effectiveGridSize;

    // Single paint object reused to avoid garbage collection overhead
    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (double x = minGlowX; x <= maxGlowX; x += effectiveGridSize) {
      for (double y = minGlowY; y <= maxGlowY; y += effectiveGridSize) {
        // Translate point to center (using primitives to avoid Offset allocation)
        final double dx = x - glowPos.dx;
        final double dy = y - glowPos.dy;

        // Rotate point back by -theta to align with ellipse axes
        final double rx = dx * cosAngle + dy * sinAngle;
        final double ry = -dx * sinAngle + dy * cosAngle;

        // Ellipse math: (rx/a)^2 + (ry/b)^2
        final double ellipseVal = (rx * rx) / (a * a) + (ry * ry) / (b * b);

        if (ellipseVal < 1.0) {
          // Cubic smoothstep interpolation (proximity value: 1 at center, 0 at boundary)
          final double t = (1.0 - math.sqrt(ellipseVal)).clamp(0.0, 1.0);
          final double strength = (3 * t * t - 2 * t * t * t) * glowOpacity;

          // Interpolate radius and color values
          // Dot growth factor reduced to 0.6 for a subtle/premium glow effect
          final double targetRadius =
              (AppConfig.grid.dotRadius + 0.6 * strength) / scale;
          final Color dynamicColor = Color.lerp(
            dotColor,
            glowColor.withValues(alpha: strength),
            strength,
          )!;

          glowPaint.color = dynamicColor;
          canvas.drawCircle(Offset(x, y), targetRadius, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowGridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.visualGlowPos != visualGlowPos ||
        oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.velocity != velocity;
  }
}
