import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/shared/utils/color_utils.dart';

class GridLayer extends StatelessWidget {
  final ViewportStateGrid viewportState;

  const GridLayer({super.key, required this.viewportState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = ColorUtils.isDark(backgroundColor);

    final Color dotColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color.fromARGB(233, 214, 214, 214);

    return CustomPaint(
      size: viewportState.viewportSize,
      painter: _GridPainter(
        visibleRect: viewportState.visibleRect,
        scale: viewportState.scale,
        viewportSize: viewportState.viewportSize,
        backgroundColor: backgroundColor,
        dotColor: dotColor,
      ),
      willChange: true, // high-frequency updates during gestures
    );
  }
}

class _GridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Size viewportSize;
  final Color backgroundColor;
  final Color dotColor;

  _GridPainter({
    required this.visibleRect,
    required this.scale,
    required this.viewportSize,
    required this.backgroundColor,
    required this.dotColor,
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
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor;
  }
}
