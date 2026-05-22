import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../presentation/graph_metrics.dart';
import '../../presentation/view_state.dart';
import '../../presentation/strategies/relation_style_strategy.dart';
import '../../presentation/strategies/relation_layout_strategy.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState> nodeViewStates; // Use ViewStates for real-time positions
  final Set<String> selectedEntities; // Selection state from NodeRenderState
  final Map<String, (Offset start, Offset end)> draggingOverrides;

  RelationPainter(
    this.relations,
    this.nodeViewStates,
    this.selectedEntities, {
    this.draggingOverrides = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final from = nodeViewStates[rel.fromNodeId];
      final to = nodeViewStates[rel.toNodeId];

      if (from == null || to == null) continue;

      final layoutStrategy = RelationLayoutStrategy.fromType(rel.layout?.strategyType);

      Offset start;
      Offset end;

      final override = draggingOverrides[rel.id];
      if (override != null) {
        start = override.$1;
        end = override.$2;
      } else {
        final (resolvedStart, resolvedEnd) = layoutStrategy.resolveEndpoints(rel, from, to);
        start = resolvedStart;
        end = resolvedEnd;
      }

      // Centralized Style Resolution
      final resolved = RelationStyleStrategy.resolveStyle(rel);

      // Apply selection styling from NodeRenderState.selectedEntities
      final isSelected = selectedEntities.contains(rel.id);
      paint.color = isSelected
          ? AppConfig.visuals.selectionAccent
          : Color(resolved.strokeColor);
      paint.strokeWidth = isSelected
          ? AppConfig.relation.selectedStrokeWidth
          : resolved.strokeWidth.toDouble();

      // Draw relation path (straight line or Bezier curve)
      final path = layoutStrategy.computePath(start, end, from, to, rel);
      canvas.drawPath(path, paint);

      // If selected, draw the two tip handlers
      if (isSelected) {
        final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
          rel,
          from,
          to,
          overrideStart: draggingOverrides[rel.id]?.$1,
          overrideEnd: draggingOverrides[rel.id]?.$2,
        );

        final handlePaint = Paint()
          ..color = AppConfig.visuals.selectionAccent
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(handleStart, 6.0, borderPaint);
        canvas.drawCircle(handleStart, 5.0, handlePaint);

        canvas.drawCircle(handleEnd, 6.0, borderPaint);
        canvas.drawCircle(handleEnd, 5.0, handlePaint);
      }

      // Draw Label (Centered on the layout path)
      if (rel.verb.isNotEmpty) {
        final mid = layoutStrategy.computeLabelPosition(start, end, from, to, rel);
        _drawText(canvas, rel.verb, mid);
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
