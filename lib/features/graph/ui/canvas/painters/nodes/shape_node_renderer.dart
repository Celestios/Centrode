import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../widgets/node_visual_constants.dart';
import '../drawing_node_painter.dart';

class ShapeNodeRenderer {
  const ShapeNodeRenderer();

  static RRect buildRRect(
    Rect rect,
    NodeStyle style, [
    double extraRadius = 0.0,
    double scale = 1.0,
  ]) {
    final radius = style.shape == 'circle'
        ? Radius.circular(rect.shortestSide / 2)
        : Radius.circular(style.borderRadius + extraRadius);
    return RRect.fromRectAndRadius(rect, radius);
  }

  static void paintDrawingPaths(
    Canvas canvas,
    DrawingUiNode node,
    Offset pos,
    NodeStyle style,
    Size size, {
    required bool isHighlighted,
    required bool isEditing,
    required bool isSelected,
    required bool isHovered,
    required Color selectionColor,
    required Color hoverColor,
  }) {
    canvas.save();
    canvas.translate(pos.dx + style.padding, pos.dy + style.padding);

    if (isHighlighted) {
      final Color highlightColor;
      if (isEditing) {
        highlightColor = Color(NodeVisualConstants.editingBorderColor);
      } else if (isSelected) {
        highlightColor = selectionColor;
      } else {
        highlightColor = hoverColor;
      }
      paintDrawingOutline(
        canvas,
        node.parsedPaths,
        highlightColor,
        node.brushThickness,
      );
    }

    final drawingPainter = DrawingNodePainter(
      paths: node.paths,
      parsedPaths: node.parsedPaths,
      brushColor: node.brushColor,
      brushThickness: node.brushThickness,
      brushType: node.brushType.name,
    );
    drawingPainter.paint(canvas, size);

    canvas.restore();
  }

  static void paintDrawingOutline(
    Canvas canvas,
    List<List<Offset>> parsedPaths,
    Color color,
    double brushThickness,
  ) {
    final double offset = brushThickness * 0.5 + 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final points in parsedPaths) {
      if (points.length < 2) continue;

      for (int i = 0; i < points.length - 1; i++) {
        final s1 = points[i];
        final s2 = points[i + 1];
        final dir = s2 - s1;
        final len = dir.distance;
        if (len == 0) continue;
        final normal = Offset(-dir.dy / len, dir.dx / len) * offset;

        final outerPath = Path()
          ..moveTo(s1.dx + normal.dx, s1.dy + normal.dy)
          ..lineTo(s2.dx + normal.dx, s2.dy + normal.dy);
        final innerPath = Path()
          ..moveTo(s1.dx - normal.dx, s1.dy - normal.dy)
          ..lineTo(s2.dx - normal.dx, s2.dy - normal.dy);

        canvas.drawPath(outerPath, paint);
        canvas.drawPath(innerPath, paint);
      }
    }
  }
}
