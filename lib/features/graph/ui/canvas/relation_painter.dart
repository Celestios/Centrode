import 'package:flutter/material.dart';
import '../../domain/models.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, UiNode> nodeLookup; // To find positions

  RelationPainter(this.relations, this.nodeLookup);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final from = nodeLookup[rel.fromNodeId];
      final to = nodeLookup[rel.toNodeId];

      if (from == null || to == null) continue;

      // Calculate centers
      final start = from.position + Offset(from.size.width / 2, from.size.height / 2);
      final end = to.position + Offset(to.size.width / 2, to.size.height / 2);

      paint.color = rel.color;

      // Draw straight line (Bezier curves can be added later)
      canvas.drawLine(start, end, paint);

      // Draw Label (Simplified)
      if (rel.label.isNotEmpty) {
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        _drawText(canvas, rel.label, mid);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 10, backgroundColor: Colors.white),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    return true; // Optimize later to check list equality
  }
}