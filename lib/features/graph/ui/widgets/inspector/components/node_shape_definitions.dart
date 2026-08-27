import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Supported node body shape descriptors.
class NodeShapeDefinition {
  final String id;
  final String label;

  const NodeShapeDefinition({
    required this.id,
    required this.label,
  });
}

const List<NodeShapeDefinition> kAvailableNodeShapes = [
  NodeShapeDefinition(id: 'rounded', label: 'Rounded'),
  NodeShapeDefinition(id: 'sharp', label: 'Sharp'),
  NodeShapeDefinition(id: 'capsule', label: 'Capsule'),
  NodeShapeDefinition(id: 'circle', label: 'Circle'),
  NodeShapeDefinition(id: 'ellipse', label: 'Ellipse'),
  NodeShapeDefinition(id: 'cloudy', label: 'Cloudy'),
  NodeShapeDefinition(id: 'diamond', label: 'Diamond'),
  NodeShapeDefinition(id: 'hexagon', label: 'Hexagon'),
  NodeShapeDefinition(id: 'cylinder', label: 'Cylinder'),
];

/// Computes a vector Path for any node shape given target bounding [rect].
Path buildShapePath(String shape, Rect rect, {double cornerRadius = 8.0}) {
  final path = Path();
  switch (shape) {
    case 'circle':
      final radius = math.min(rect.width, rect.height) / 2;
      path.addOval(Rect.fromCircle(center: rect.center, radius: radius));
      break;

    case 'ellipse':
      path.addOval(rect);
      break;

    case 'capsule':
      final r = rect.height / 2;
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
      break;

    case 'sharp':
      path.addRect(rect);
      break;

    case 'diamond':
      final cx = rect.center.dx;
      final cy = rect.center.dy;
      path.moveTo(cx, rect.top);
      path.lineTo(rect.right, cy);
      path.lineTo(cx, rect.bottom);
      path.lineTo(rect.left, cy);
      path.close();
      break;

    case 'hexagon':
      final w = rect.width;
      final h = rect.height;
      final l = rect.left;
      final t = rect.top;
      final r = rect.right;
      final b = rect.bottom;
      path.moveTo(l + w * 0.25, t);
      path.lineTo(r - w * 0.25, t);
      path.lineTo(r, t + h * 0.5);
      path.lineTo(r - w * 0.25, b);
      path.lineTo(l + w * 0.25, b);
      path.lineTo(l, t + h * 0.5);
      path.close();
      break;

    case 'cylinder':
      final w = rect.width;
      final h = rect.height;
      final capH = h * 0.3;
      // Top oval
      path.addOval(Rect.fromLTWH(rect.left, rect.top, w, capH));
      // Body
      final bodyPath = Path();
      bodyPath.moveTo(rect.left, rect.top + capH * 0.5);
      bodyPath.lineTo(rect.left, rect.bottom - capH * 0.5);
      bodyPath.arcToPoint(
        Offset(rect.right, rect.bottom - capH * 0.5),
        radius: Radius.elliptical(w * 0.5, capH * 0.5),
        clockwise: false,
      );
      bodyPath.lineTo(rect.right, rect.top + capH * 0.5);
      path.addPath(bodyPath, Offset.zero);
      break;

    case 'cloudy':
      final w = rect.width;
      final h = rect.height;
      final l = rect.left;
      final t = rect.top;
      final r = rect.right;
      final b = rect.bottom;

      path.moveTo(l + w * 0.2, b - h * 0.15);
      path.quadraticBezierTo(l, b - h * 0.2, l + w * 0.05, t + h * 0.55);
      path.quadraticBezierTo(l, t + h * 0.25, l + w * 0.3, t + h * 0.2);
      path.quadraticBezierTo(l + w * 0.5, t - h * 0.05, l + w * 0.7, t + h * 0.15);
      path.quadraticBezierTo(r, t + h * 0.2, r - w * 0.05, t + h * 0.55);
      path.quadraticBezierTo(r + w * 0.05, b - h * 0.2, r - w * 0.2, b - h * 0.15);
      path.quadraticBezierTo(l + w * 0.5, b + h * 0.05, l + w * 0.2, b - h * 0.15);
      path.close();
      break;

    case 'rounded':
    default:
      path.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      );
      break;
  }
  return path;
}

/// Custom vector shape icon widget for [UnravelSlider] cells.
class NodeShapeVectorIcon extends StatelessWidget {
  final String shape;
  final Color color;
  final double size;

  const NodeShapeVectorIcon({
    super.key,
    required this.shape,
    required this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.68),
      painter: _NodeShapeVectorIconPainter(shape: shape, color: color),
    );
  }
}

class _NodeShapeVectorIconPainter extends CustomPainter {
  final String shape;
  final Color color;

  _NodeShapeVectorIconPainter({
    required this.shape,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2.0, 2.0, size.width - 4.0, size.height - 4.0);
    final path = buildShapePath(shape, rect, cornerRadius: 5.0);

    // Subtle glass fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Outer border stroke
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _NodeShapeVectorIconPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
