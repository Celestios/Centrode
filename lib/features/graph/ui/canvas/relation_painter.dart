import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../presentation/graph_metrics.dart';
import '../../presentation/view_state.dart';
import '../../presentation/strategies/relation_style_strategy.dart';
import '../../presentation/strategies/relation_layout_strategy.dart';
import '../../presentation/strategies/routing/relation_layout_context.dart';
import '../../engine/base_interaction_state.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState> nodeViewStates; // Use ViewStates for real-time positions
  final Set<String> selectedEntities; // Selection state from NodeRenderState
  final Map<String, List<Offset>> pathCache;
  final Map<String, (Offset start, Offset end)> draggingOverrides;
  final CanvasInteractionState? interactionState;
  final ThemeData theme;

  RelationPainter(
    this.relations,
    this.nodeViewStates,
    this.selectedEntities, {
    required this.pathCache,
    this.draggingOverrides = const {},
    this.interactionState,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final layoutContext = RelationLayoutContext(
      nodeViewStates: nodeViewStates,
      relations: relations,
      pathCache: pathCache,
    );

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

      // Apply selection styling or dragging styling
      final isSelected = selectedEntities.contains(rel.id);
      final drag = (interactionState is RelationTipDragging && (interactionState as RelationTipDragging).relationId == rel.id)
          ? interactionState as RelationTipDragging
          : null;

      if (drag != null) {
        paint.color = drag.snappedTargetNodeId != null
            ? Colors.green
            : Colors.blueAccent;
        paint.strokeWidth = AppConfig.relation.selectedStrokeWidth;
      } else {
        paint.color = isSelected
            ? AppConfig.visuals.selectionAccent
            : Color(resolved.strokeColor);
        paint.strokeWidth = isSelected
            ? AppConfig.relation.selectedStrokeWidth
            : resolved.strokeWidth.toDouble();
      }

      // Draw relation path (straight line or Bezier curve)
      final path = layoutStrategy.computePath(start, end, from, to, rel, layoutContext);
      
      final strokePattern = resolved.strokePattern;
      if (strokePattern == 'dashed' || strokePattern == 'dotted') {
        final decoratedPath = _createPatternedPath(path, strokePattern);
        canvas.drawPath(decoratedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      // If selected, draw the two tip handles
      if (isSelected) {
        final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
          rel,
          from,
          to,
          layoutContext,
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
        final mid = layoutStrategy.computeLabelPosition(start, end, from, to, rel, layoutContext);
        _drawText(canvas, rel.verb, mid, paint.color, paint.strokeWidth);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color strokeColor, double strokeWidth) {
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Compute dimensions with padding for the wrap-around container
    const double paddingX = 8.0;
    const double paddingY = 4.0;
    final double w = textPainter.width + paddingX * 2;
    final double h = textPainter.height + paddingY * 2;

    // Define the pill-shaped container aligned at center pos
    final rect = Rect.fromCenter(center: pos, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));

    // Fill with canvas background to mask relation line and grid dots underneath
    final fillPaint = Paint()
      ..color = theme.scaffoldBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Stroke with relation line color/thickness to simulate wrapping around it
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, strokePaint);

    // Draw the text
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  Path _createPatternedPath(Path source, String pattern) {
    final Path dest = Path();
    final double dashLen = pattern == 'dashed' ? 8.0 : 2.0;
    final double gapLen = pattern == 'dashed' ? 6.0 : 4.0;

    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLen : gapLen;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, (distance + len).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    // Always repaint when movementNotifier pulses
    // Could optimize by comparing positions if needed
    return true;
  }
}
