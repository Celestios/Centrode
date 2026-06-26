import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart' as rust;
import 'package:mycelium/src/rust/domain/relation_engine/config.dart' as rust_config;
import 'package:mycelium/src/rust/domain/relation_engine/geometry.dart' as rust_geom;
import '../../../models/models.dart';
import '../../../engine/config.dart';
import '../../../presentation/view_state.dart';
import '../../../presentation/strategies/relation_style_strategy.dart';
import '../../../presentation/strategies/relation_layout_strategy.dart';
import '../../../presentation/routing/relation_layout_context.dart';
import '../../../presentation/relation_engine_state.dart';
import '../../../engine/base_interaction_state.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState> nodeViewStates;
  final Set<String> selectedEntities;
  final Map<String, List<Offset>> pathCache;
  final Map<String, (Offset start, Offset end)> draggingOverrides = {};
  final CanvasInteractionState? interactionState;
  final RelationEngineState? relationEngine;
  final ThemeData theme;

  RelationPainter(
    this.relations,
    this.nodeViewStates,
    this.selectedEntities, {
    required this.pathCache,
    this.relationEngine,
    this.interactionState,
    required this.theme,
  }) {
    _computeDraggingOverrides();
  }

  void _computeDraggingOverrides() {
    final state = interactionState;
    if (state is RelationTipDragging) {
      final drag = state;
      UiRelation? rel;
      for (final r in relations) {
        if (r.id == drag.relationId) {
          rel = r;
          break;
        }
      }
      if (rel != null) {
        final from = nodeViewStates[rel.fromNodeId];
        final to = nodeViewStates[rel.toNodeId];
        if (from != null && to != null) {
          final Offset dragPos;
          if (drag.snappedTargetNodeId != null &&
              drag.snappedTargetSide != null) {
            final targetVs = nodeViewStates[drag.snappedTargetNodeId!];
            dragPos = targetVs != null
                ? targetVs.getPortPosition(drag.snappedTargetSide!)
                : drag.currentCursorPosition;
          } else {
            dragPos = drag.currentCursorPosition;
          }

          final layoutStrategy = RelationLayoutStrategy.fromType(
            rel.layout?.strategyType,
          );
          final (resolvedStart, resolvedEnd) = layoutStrategy.resolveEndpoints(
            rel,
            from,
            to,
            overrideStart: drag.isStartTip ? dragPos : null,
            overrideEnd: !drag.isStartTip ? dragPos : null,
          );
          draggingOverrides[rel.id] = (resolvedStart, resolvedEnd);
        }
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    Color strokeColor,
    double strokeWidth,
  ) {
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const double paddingX = 8.0;
    const double paddingY = 4.0;
    final double w = textPainter.width + paddingX * 2;
    final double h = textPainter.height + paddingY * 2;

    final rect = Rect.fromCenter(center: pos, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));

    final fillPaint = Paint()
      ..color = theme.scaffoldBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, strokePaint);

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
            metric.extractPath(
              distance,
              (distance + len).clamp(0.0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  void _drawVariableWidthPoints(
    Canvas canvas,
    List<rust_geom.Point> points,
    List<double> widths,
    Color color,
  ) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i].x, points[i].y);
      final p2 = Offset(points[i + 1].x, points[i + 1].y);
      final w = i < widths.length ? widths[i] : widths.last;
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, segmentPaint);
    }
  }

  Path _buildPathFromComputed(List<rust_geom.Point> points) {
    if (points.isEmpty) return Path();
    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    return path;
  }

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

      final layoutStrategy = RelationLayoutStrategy.fromType(
        rel.layout?.strategyType,
      );

      final override = draggingOverrides[rel.id];
      final isDragging = override != null;
      final nodeDragged = interactionState is NodeDragging &&
          (rel.fromNodeId == (interactionState as NodeDragging).nodeId ||
           rel.toNodeId == (interactionState as NodeDragging).nodeId);

      rust.ComputedRelation? cached;
      if (!isDragging && !nodeDragged && relationEngine != null) {
        cached = relationEngine!.cache[rel.id];
      }

      Offset start;
      Offset end;
      Path path;
      Offset labelPos;

      if (cached != null) {
        start = Offset(cached.pathPoints.first.x, cached.pathPoints.first.y);
        end = Offset(cached.pathPoints.last.x, cached.pathPoints.last.y);
        path = _buildPathFromComputed(cached.pathPoints);
        labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);
      } else {
        if (isDragging) {
          start = override.$1;
          end = override.$2;
        } else {
          final (resolvedStart, resolvedEnd) = layoutStrategy.resolveEndpoints(
            rel,
            from,
            to,
          );
          start = resolvedStart;
          end = resolvedEnd;
        }

        path = layoutStrategy.computePath(
          start,
          end,
          from,
          to,
          rel,
          layoutContext,
        );
        labelPos = layoutStrategy.computeLabelPosition(
          start,
          end,
          from,
          to,
          rel,
          layoutContext,
        );
      }

      final resolved = RelationStyleStrategy.resolveStyle(rel);

      final isSelected = selectedEntities.contains(rel.id);
      final drag =
          (interactionState is RelationTipDragging &&
              (interactionState as RelationTipDragging).relationId == rel.id)
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

      final isVariableWidth = cached != null && cached.bodyType != rust_config.BodyType.uniform;

      if (isVariableWidth) {
        _drawVariableWidthPoints(canvas, cached.pathPoints, cached.bodyWidths, paint.color);
      } else {
        final strokePattern = resolved.strokePattern;
        if (strokePattern == 'dashed' || strokePattern == 'dotted') {
          final decoratedPath = _createPatternedPath(path, strokePattern);
          canvas.drawPath(decoratedPath, paint);
        } else {
          canvas.drawPath(path, paint);
        }
      }

      final endpointColor = isSelected
          ? AppConfig.visuals.selectionAccent
          : Color(resolved.strokeColor);

      if (resolved.startShape != null && resolved.startShape != EndpointShape.none) {
        final fromCenter = from.rect.center;
        final outwardDir = (start - fromCenter).direction;
        final offset = Offset(cos(outwardDir), sin(outwardDir)) * resolved.arrowSize * 0.5;
        _drawEndpointShape(canvas, start + offset, outwardDir + pi, resolved.startShape!, endpointColor.withAlpha(255), resolved.arrowSize);
      }
      if (resolved.endShape != null && resolved.endShape != EndpointShape.none) {
        final toCenter = to.rect.center;
        final outwardDir = (end - toCenter).direction;
        final offset = Offset(cos(outwardDir), sin(outwardDir)) * resolved.arrowSize * 0.5;
        _drawEndpointShape(canvas, end + offset, outwardDir + pi, resolved.endShape!, endpointColor.withAlpha(255), resolved.arrowSize);
      }

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

      if (rel.verb.isNotEmpty) {
        _drawText(canvas, rel.verb, labelPos, paint.color, paint.strokeWidth);
      }
    }
  }

  void _drawEndpointShape(Canvas canvas, Offset position, double direction, EndpointShape shape, Color color, double size) {
    final half = size / 2;
    final opaqueColor = color.withAlpha(255);
    final fillPaint = Paint()
      ..color = opaqueColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = opaqueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (shape) {
      case EndpointShape.none:
        break;
      case EndpointShape.arrow:
        final path = Path();
        path.moveTo(position.dx + cos(direction) * size, position.dy + sin(direction) * size);
        path.lineTo(position.dx + cos(direction + 2.5) * half, position.dy + sin(direction + 2.5) * half);
        path.lineTo(position.dx + cos(direction - 2.5) * half, position.dy + sin(direction - 2.5) * half);
        path.close();
        canvas.drawPath(path, fillPaint);
      case EndpointShape.openArrow:
        final path = Path();
        path.moveTo(position.dx + cos(direction) * size, position.dy + sin(direction) * size);
        path.lineTo(position.dx + cos(direction + 2.5) * half, position.dy + sin(direction + 2.5) * half);
        path.moveTo(position.dx + cos(direction) * size, position.dy + sin(direction) * size);
        path.lineTo(position.dx + cos(direction - 2.5) * half, position.dy + sin(direction - 2.5) * half);
        canvas.drawPath(path, strokePaint);
      case EndpointShape.circle:
        canvas.drawCircle(position, half, fillPaint);
      case EndpointShape.diamond:
        final path = Path();
        path.moveTo(position.dx, position.dy - half);
        path.lineTo(position.dx + half, position.dy);
        path.lineTo(position.dx, position.dy + half);
        path.lineTo(position.dx - half, position.dy);
        path.close();
        canvas.drawPath(path, fillPaint);
      case EndpointShape.square:
        final rect = Rect.fromCenter(center: position, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    if (identical(oldDelegate.relations, relations) == false) return true;
    if (oldDelegate.selectedEntities != selectedEntities) return true;
    if (identical(oldDelegate.nodeViewStates, nodeViewStates) == false) return true;
    if (oldDelegate.interactionState != interactionState) return true;
    if (oldDelegate.theme != theme) return true;
    if (oldDelegate.pathCache != pathCache) return true;
    if (oldDelegate.draggingOverrides != draggingOverrides) return true;
    if (oldDelegate.relationEngine != relationEngine) return true;
    return false;
  }
}
