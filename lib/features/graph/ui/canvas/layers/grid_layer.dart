import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/config/app_config.dart';

class GridLayer extends StatelessWidget {
  final TransformationController transformController;
  final Size viewportSize;

  const GridLayer({
    super.key,
    required this.transformController,
    required this.viewportSize,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Matrix4>(
      valueListenable: transformController,
      builder: (context, transform, _) {
        return CustomPaint(
          size: viewportSize,
          painter: _GridPainter(
            transform: transform,
            viewportSize: viewportSize,
          ),
          willChange: true, // Hint to Flutter engine for high-frequency updates
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Matrix4 transform;
  final Size viewportSize;

  _GridPainter({required this.transform, required this.viewportSize});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Extract scale and calculate LOD multiplier
    final double scale = transform.getMaxScaleOnAxis();
    if (scale <= 0) return; // Singular matrix guard

    // Dynamic Level of Detail (LOD): Scale up the grid mathematically as we zoom out
    final double lod = max(1.0, (1.0 / scale).floorToDouble());
    final double effectiveGridSize = AppConfig.graph.grid.baseSize * lod;

    // 2. Find the visible bounds in Canvas Space via Inverse Transformation
    final Matrix4 inverse = Matrix4.inverted(transform);
    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(viewportSize.width, viewportSize.height),
    );

    final Rect visibleRect = Rect.fromPoints(topLeft, bottomRight);

    // 3. Calculate Modulo Starting Points
    final double startX =
        (visibleRect.left / effectiveGridSize).floor() * effectiveGridSize;
    final double startY =
        (visibleRect.top / effectiveGridSize).floor() * effectiveGridSize;

    // 4. Batch Points for O(1) bulk rendering
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

    // 5. Render
    final paint = Paint()
      ..color = AppConfig.graph.grid.dotColor
      ..strokeCap = StrokeCap.round
      // Divide radius by scale so dots remain physically the same size on screen
      ..strokeWidth = (AppConfig.graph.grid.dotRadius * 2) / scale;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.transform != transform;
  }
}
