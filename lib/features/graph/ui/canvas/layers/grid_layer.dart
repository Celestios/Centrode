import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../presentation/graph_metrics.dart';
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
      _ticker!.start();
    } else if (mousePos == null && !_ticker!.isActive && _glowOpacity > 0.0) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    final physicalMousePos = widget.mousePositionNotifier.value;

    if (physicalMousePos == null) {
      // Smoothly decay/fade out the glow
      setState(() {
        _glowOpacity = (_glowOpacity - 0.08).clamp(0.0, 1.0);
        if (_glowOpacity == 0.0) {
          _visualGlowPos = null;
          _ticker!.stop();
        }
      });
    } else {
      // Smoothly fade in/interpolate the glow
      setState(() {
        _glowOpacity = (_glowOpacity + 0.12).clamp(0.0, 1.0);

        if (_visualGlowPos == null) {
          _visualGlowPos = physicalMousePos;
        } else {
          // Fluid spring interpolation: Visual center trails physical position
          const double damping = 0.22;
          _visualGlowPos = Offset(
            lerpDouble(_visualGlowPos!.dx, physicalMousePos.dx, damping)!,
            lerpDouble(_visualGlowPos!.dy, physicalMousePos.dy, damping)!,
          );
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
        ? Colors.white.withValues(alpha: 0.15)
        : const Color.fromARGB(233, 214, 214, 214);

    final Color glowColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.8)
        : theme.colorScheme.primary.withValues(alpha: 0.6);

    return RepaintBoundary(
      child: CustomPaint(
        size: widget.viewportState.viewportSize,
        painter: _GridPainter(
          visibleRect: widget.viewportState.visibleRect,
          scale: widget.viewportState.scale,
          viewportSize: widget.viewportState.viewportSize,
          backgroundColor: backgroundColor,
          dotColor: dotColor,
          glowColor: glowColor,
          visualGlowPos: _visualGlowPos,
          glowOpacity: _glowOpacity,
        ),
        willChange: true, // high-frequency updates during gestures
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Size viewportSize;
  final Color backgroundColor;
  final Color dotColor;
  final Color glowColor;
  final Offset? visualGlowPos;
  final double glowOpacity;

  _GridPainter({
    required this.visibleRect,
    required this.scale,
    required this.viewportSize,
    required this.backgroundColor,
    required this.dotColor,
    required this.glowColor,
    required this.visualGlowPos,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    canvas.drawRect(
      visibleRect,
      Paint()..color = backgroundColor,
    );

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

    // Dynamic Hover Glow overlay
    final glowPosLocal = visualGlowPos;
    if (glowPosLocal != null && glowOpacity > 0.0) {
      // Calculate logical coordinates for the mouse position
      final Offset glowPos = visibleRect.topLeft + (glowPosLocal / scale);
      const double influenceRadius = 160.0;

      // Find boundaries in logical space of grid dots inside the influence radius
      final double minGlowX = ((glowPos.dx - influenceRadius) / effectiveGridSize).floor() * effectiveGridSize;
      final double maxGlowX = ((glowPos.dx + influenceRadius) / effectiveGridSize).ceil() * effectiveGridSize;
      final double minGlowY = ((glowPos.dy - influenceRadius) / effectiveGridSize).floor() * effectiveGridSize;
      final double maxGlowY = ((glowPos.dy + influenceRadius) / effectiveGridSize).ceil() * effectiveGridSize;

      for (double x = minGlowX; x <= maxGlowX; x += effectiveGridSize) {
        for (double y = minGlowY; y <= maxGlowY; y += effectiveGridSize) {
          final Offset dotPos = Offset(x, y);
          final double distance = (dotPos - glowPos).distance;

          if (distance < influenceRadius) {
            // Cubic smoothstep interpolation (proximity value: 1 at cursor center, 0 at boundary)
            final double t = (1.0 - (distance / influenceRadius)).clamp(0.0, 1.0);
            final double strength = (3 * t * t - 2 * t * t * t) * glowOpacity;

            // Interpolate radius and color values
            final double targetRadius = (AppConfig.grid.dotRadius + 1.7 * strength) / scale;
            final Color dynamicColor = Color.lerp(
              dotColor,
              glowColor.withValues(alpha: strength),
              strength,
            )!;

            final glowPaint = Paint()
              ..color = dynamicColor
              ..style = PaintingStyle.fill;

            canvas.drawCircle(dotPos, targetRadius, glowPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.visualGlowPos != visualGlowPos ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
