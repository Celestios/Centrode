import 'package:flutter/material.dart';
import 'drawing_color_utils.dart';

class DrawingNodePainter extends CustomPainter {
  final List<String> paths;
  final List<List<Offset>>? parsedPaths;
  final String brushColor;
  final double brushThickness;
  final String brushType;

  late final Color _parsedColor = DrawingColorUtils.resolveBrushColor(brushColor, brushType);

  DrawingNodePainter({
    required this.paths,
    this.parsedPaths,
    required this.brushColor,
    required this.brushThickness,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = _parsedColor;


    final paint = Paint()
      ..color = color
      ..strokeWidth = brushThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final resolvedPaths = parsedPaths ?? paths.map((pathStr) {
      return pathStr
          .split(';')
          .map((p) {
            final coords = p.split(',');
            if (coords.length < 2) return null;
            final x = double.tryParse(coords[0]);
            final y = double.tryParse(coords[1]);
            if (x == null || y == null) return null;
            return Offset(x, y);
          })
          .whereType<Offset>()
          .toList();
    }).toList();

    for (final points in resolvedPaths) {
      if (points.isEmpty) continue;
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingNodePainter oldDelegate) {
    return oldDelegate.paths != paths ||
        oldDelegate.parsedPaths != parsedPaths ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.brushThickness != brushThickness ||
        oldDelegate.brushType != brushType;
  }
}
