import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/engine/base_interaction_state.dart';

class GridLayer extends StatelessWidget {
  final ViewportStateGrid viewportState;

  const GridLayer({super.key, required this.viewportState});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: viewportState.viewportSize,
      painter: _GridPainter(
        visibleRect: viewportState.visibleRect,
        scale: viewportState.scale,
        viewportSize: viewportState.viewportSize,
      ),
      willChange: true, // high-frequency updates during gestures
    );
  }
}

class _GridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Size viewportSize;

  _GridPainter({
    required this.visibleRect,
    required this.scale,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    canvas.drawRect(
      visibleRect,
      Paint()..color = AppConfig.canvas.backgroundColor,
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
      ..color = AppConfig.grid.dotColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (AppConfig.grid.dotRadius * 2) / scale;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect || oldDelegate.scale != scale;
  }
}
