import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable subtle dot blueprint grid painter for showcase cards.
class ShowcaseGridPainter extends CustomPainter {
  final Color dotColor;

  const ShowcaseGridPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 16.0;
    for (double x = 8.0; x < size.width; x += spacing) {
      for (double y = 8.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShowcaseGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

/// Utility to draw dashed/dotted strokes along a [Path] without duplicating metric extraction loops.
void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required String borderStyle,
}) {
  if (borderStyle == 'solid') {
    canvas.drawPath(path, paint);
    return;
  }

  final dashWidth = borderStyle == 'dashed' ? 6.0 : 2.0;
  final dashSpace = borderStyle == 'dashed' ? 4.0 : 3.0;

  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < metric.length) {
      final len = math.min(dashWidth, metric.length - distance);
      final extract = metric.extractPath(distance, distance + len);
      canvas.drawPath(extract, paint);
      distance += dashWidth + dashSpace;
    }
  }
}
