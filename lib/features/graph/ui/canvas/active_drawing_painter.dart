import 'package:flutter/material.dart';

/// Painter that renders the transient, active drawing stroke in canvas coordinates.
class ActiveDrawingPainter extends CustomPainter {
  final List<Offset> points;
  final String brushColor;
  final double brushThickness;
  final String brushType;

  ActiveDrawingPainter({
    required this.points,
    required this.brushColor,
    required this.brushThickness,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    Color color;
    try {
      final hex = brushColor.replaceFirst('#', '').replaceFirst('0x', '');
      if (hex.length == 6) {
        color = Color(int.parse('FF$hex', radix: 16));
      } else {
        color = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      color = const Color(0xFF00E5FF);
    }

    if (brushType == 'highlighter') {
      color = color.withValues(alpha: 0.4);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ActiveDrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.brushThickness != brushThickness ||
        oldDelegate.brushType != brushType;
  }
}
