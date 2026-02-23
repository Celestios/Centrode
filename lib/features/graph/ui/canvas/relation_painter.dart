import 'package:flutter/material.dart';
import '../../domain/models.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState>
  nodeViewStates; // Use ViewStates for real-time positions
  final Set<String> selectedEntities; // Selection state from GraphUIController

  RelationPainter(this.relations, this.nodeViewStates, this.selectedEntities);

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
      final startSize = from.sizeNotifier.value;
      final endSize = to.sizeNotifier.value;

      // [REFACTORED]: O(1) Geometry extraction directly from ViewState
      final start = startSize == Size.zero
          ? startPos +
                const Offset(100, 30) // Fallback
          : from.rightPort;

      final end = endSize == Size.zero
          ? endPos +
                const Offset(0, 30) // Fallback
          : to.leftPort;

      // [UPDATED] Apply selection styling from GraphUIController.selectedEntities
      final isSelected = selectedEntities.contains(rel.id);
      paint.color = isSelected ? const Color(0xFF42A5F5) : rel.color;
      paint.strokeWidth = isSelected ? 3.0 : 1.5;

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
      style: const TextStyle(
        color: Colors.black,
        fontSize: 10,
        backgroundColor: Colors.white,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    // Always repaint when movementNotifier pulses
    // Could optimize by comparing positions if needed
    return true;
  }
}
