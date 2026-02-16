import 'package:flutter/material.dart';
import '../../domain/models.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState> nodeViewStates; // Use ViewStates for real-time positions

  RelationPainter(this.relations, this.nodeViewStates);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final from = nodeViewStates[rel.fromNodeId];
      final to = nodeViewStates[rel.toNodeId];

      if (from == null || to == null) continue;

      // Access .value directly for the most current position during the pulse
      final startPos = from.positionNotifier.value;
      final endPos = to.positionNotifier.value;

      // Dynamic vector geometry: use actual node sizes from ViewState
      // Guard against early render passes where layout frames resolve to Size.zero
      final startSize = from.sizeNotifier.value;
      final endSize = to.sizeNotifier.value;

      // Map correctly to the interaction ports (Right Center -> Left Center)
      final startOffset = startSize == Size.zero
          ? const Offset(100, 30) // Fallback to default node size (100x60) right port
          : Offset(startSize.width, startSize.height / 2); // Right port

      final endOffset = endSize == Size.zero
          ? const Offset(0, 30) // Fallback to default node size (100x60) left port
          : Offset(0, endSize.height / 2); // Left port

      final start = startPos + startOffset;
      final end = endPos + endOffset;

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
    // Always repaint when movementNotifier pulses
    // Could optimize by comparing positions if needed
    return true;
  }
}
