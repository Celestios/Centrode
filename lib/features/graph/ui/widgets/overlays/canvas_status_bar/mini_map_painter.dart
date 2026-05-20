import 'dart:math' as math;
import 'package:flutter/material.dart';

class MiniMapPainter extends CustomPainter {
  final List<dynamic> nodes;
  final dynamic canvasBounds;
  final Rect visibleRect;
  final Color primaryColor;

  MiniMapPainter({
    required this.nodes,
    required this.canvasBounds,
    required this.visibleRect,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Resolve bounding box coordinates
    final double minX = canvasBounds.minX.toDouble();
    final double maxX = canvasBounds.maxX.toDouble();
    final double minY = canvasBounds.minY.toDouble();
    final double maxY = canvasBounds.maxY.toDouble();

    final double graphWidth = (maxX - minX).clamp(100.0, double.infinity);
    final double graphHeight = (maxY - minY).clamp(100.0, double.infinity);

    // Padding inside the mini-map viewport
    const double padding = 8.0;
    final double areaWidth = size.width - (padding * 2);
    final double areaHeight = size.height - (padding * 2);

    // 2. Scale factor calculation to fit graph bounds into mini-map size
    final double scaleX = areaWidth / graphWidth;
    final double scaleY = areaHeight / graphHeight;
    final double scale = math.min(scaleX, scaleY);

    // Translation offsets to center graph inside mini-map
    final double offsetX = padding + (areaWidth - graphWidth * scale) / 2 - minX * scale;
    final double offsetY = padding + (areaHeight - graphHeight * scale) / 2 - minY * scale;

    Offset canvasToMiniMap(Offset pos) {
      return Offset(
        pos.dx * scale + offsetX,
        pos.dy * scale + offsetY,
      );
    }

    // 3. Draw node dots
    final nodePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      final miniPos = canvasToMiniMap(node.position);
      // Guard bounds checking
      if (miniPos.dx >= 0 && miniPos.dx <= size.width && miniPos.dy >= 0 && miniPos.dy <= size.height) {
        canvas.drawCircle(miniPos, 1.8, nodePaint);
      }
    }

    // 4. Draw current viewport rectangle
    final topLeft = canvasToMiniMap(visibleRect.topLeft);
    final bottomRight = canvasToMiniMap(visibleRect.bottomRight);
    final viewportRect = Rect.fromPoints(topLeft, bottomRight).intersect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final viewportFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final viewportBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(viewportRect, viewportFill);
    canvas.drawRect(viewportRect, viewportBorder);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return oldDelegate.nodes.length != nodes.length ||
        oldDelegate.canvasBounds != canvasBounds ||
        oldDelegate.visibleRect != visibleRect ||
        oldDelegate.primaryColor != primaryColor;
  }
}
