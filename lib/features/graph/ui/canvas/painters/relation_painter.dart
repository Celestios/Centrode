import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart' as rust_config;
import 'package:mycelium/src/rust/domain/relation_engine/geometry.dart' as rust_geom;
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart' as rust_computed;
import '../../../models/models.dart';
import '../../../engine/config.dart';
import '../../../presentation/view_state.dart';
import '../../../presentation/strategies/relation_style_strategy.dart';
import '../../../presentation/relation_utils.dart';
import '../../../store/relation_engine_state.dart';
import '../../../engine/base_interaction_state.dart';

class RelationPainter extends CustomPainter {
  final List<UiRelation> relations;
  final Map<String, NodeViewState> nodeViewStates;
  final Set<String> selectedEntities;
  final CanvasInteractionState? interactionState;
  final RelationEngineState? relationEngine;
  final ThemeData theme;

  RelationPainter(
    this.relations,
    this.nodeViewStates,
    this.selectedEntities, {
    this.relationEngine,
    this.interactionState,
    required this.theme,
  });

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

  (Offset start, Offset end) _resolveTipDragEndpoints(
    UiRelation rel,
    NodeViewState from,
    NodeViewState to,
    RelationTipDragging drag,
  ) {
    final Offset dragPos;
    if (drag.snappedTargetNodeId != null && drag.snappedTargetSide != null) {
      final targetVs = nodeViewStates[drag.snappedTargetNodeId!];
      dragPos = targetVs != null
          ? targetVs.getPortPosition(drag.snappedTargetSide!)
          : drag.currentCursorPosition;
    } else {
      dragPos = drag.currentCursorPosition;
    }

    return resolveRelationEndpoints(
      rel, from, to,
      overrideStart: drag.isStartTip ? dragPos : null,
      overrideEnd: !drag.isStartTip ? dragPos : null,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final from = nodeViewStates[rel.fromNodeId];
      final to = nodeViewStates[rel.toNodeId];

      if (from == null || to == null) continue;

      final tipDrag =
          (interactionState is RelationTipDragging &&
              (interactionState as RelationTipDragging).relationId == rel.id)
          ? interactionState as RelationTipDragging
          : null;

      Offset start;
      Offset end;
      Path path;
      Offset labelPos;

      if (tipDrag != null) {
        final endpoints = _resolveTipDragEndpoints(rel, from, to, tipDrag);
        start = endpoints.$1;
        end = endpoints.$2;
        path = buildSimpleBezierPath(start, end);
        labelPos = Offset.lerp(start, end, 0.5)!;
      } else {
        final cached = relationEngine?.cache[rel.id];
        if (cached != null && cached.pathPoints.isNotEmpty) {
          final Offset s0 = Offset(cached.pathPoints.first.x, cached.pathPoints.first.y);
          final Offset e0 = Offset(cached.pathPoints.last.x, cached.pathPoints.last.y);

          final String stateStr = interactionState?.runtimeType.toString() ?? '';
          final bool isDragging = stateStr.contains('Drag') || stateStr.contains('Dragging');

          final resolved = RelationStyleStrategy.resolveStyle(rel);
          final isSelected = selectedEntities.contains(rel.id);

          // Get local start/end widths based on body strategy
          final startWidth = cached.bodyWidths.isNotEmpty ? cached.bodyWidths.first : resolved.strokeWidth.toDouble();
          final endWidth = cached.bodyWidths.isNotEmpty ? cached.bodyWidths.last : resolved.strokeWidth.toDouble();

          final startScale = startWidth > 0.0 ? startWidth / 2.0 : 1.0;
          final endScale = endWidth > 0.0 ? endWidth / 2.0 : 1.0;

          final startMargin = (resolved.startShape != null && resolved.startShape != EndpointShape.none)
              ? resolved.arrowSize * startScale
              : 0.0;
          final endMargin = (resolved.endShape != null && resolved.endShape != EndpointShape.none)
              ? resolved.arrowSize * endScale
              : 0.0;

          final startTangent = Offset(cached.startTangent.x, cached.startTangent.y);
          final endTangent = Offset(cached.endTangent.x, cached.endTangent.y);

          final List<rust_geom.Point> pathPoints;
          final Offset startArrowCenter;
          final Offset endArrowCenter;

          if (isDragging) {
            final currentEndpoints = resolveRelationEndpoints(rel, from, to);
            final currentStart = currentEndpoints.$1;
            final currentEnd = currentEndpoints.$2;

            // Adjust trimmed endpoints dynamically in real-time
            final adjustedStart = currentStart + startTangent * startMargin;
            final adjustedEnd = currentEnd - endTangent * endMargin;

            start = adjustedStart;
            end = adjustedEnd;

            final s = adjustedStart;
            final e = adjustedEnd;

            final u0 = e0 - s0;
            final double l0 = u0.distance;
            final Offset dir0 = l0 > 1e-6 ? u0 / l0 : const Offset(1, 0);
            final Offset perp0 = Offset(-dir0.dy, dir0.dx);

            final Offset u = e - s;
            final double l = u.distance;
            final Offset dir = l > 1e-6 ? u / l : dir0;
            final Offset perp = Offset(-dir.dy, dir.dx);

            pathPoints = cached.pathPoints.map((p) {
              final p0 = Offset(p.x, p.y);
              final delta0 = p0 - s0;
              final double x = delta0.dx * dir0.dx + delta0.dy * dir0.dy;
              final double y = delta0.dx * perp0.dx + delta0.dy * perp0.dy;
              final double xPrime = x * (l0 > 1e-6 ? (l / l0) : 1.0);
              final double yPrime = y;
              final pPrime = s + dir * xPrime + perp * yPrime;
              return rust_geom.Point(x: pPrime.dx, y: pPrime.dy);
            }).toList();

            final p0Label = Offset(cached.labelPosition.x, cached.labelPosition.y);
            final delta0Label = p0Label - s0;
            final double xLabel = delta0Label.dx * dir0.dx + delta0Label.dy * dir0.dy;
            final double yLabel = delta0Label.dx * perp0.dx + delta0Label.dy * perp0.dy;
            final double xPrimeLabel = xLabel * (l0 > 1e-6 ? (l / l0) : 1.0);
            final double yPrimeLabel = yLabel;
            labelPos = s + dir * xPrimeLabel + perp * yPrimeLabel;

            startArrowCenter = currentStart + startTangent * (startMargin * 0.5);
            endArrowCenter = currentEnd - endTangent * (endMargin * 0.5);
          } else {
            pathPoints = cached.pathPoints;
            start = s0 - startTangent * startMargin;
            end = e0 + endTangent * endMargin;
            labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);

            startArrowCenter = s0 - startTangent * (startMargin * 0.5);
            endArrowCenter = e0 + endTangent * (endMargin * 0.5);
          }

          path = _buildPathFromComputed(pathPoints);

          paint.color = isSelected
              ? AppConfig.visuals.selectionAccent
              : Color(resolved.strokeColor);
          paint.strokeWidth = isSelected
              ? AppConfig.relation.selectedStrokeWidth
              : resolved.strokeWidth.toDouble();

          final isVariableWidth = cached.bodyType != rust_config.BodyType.uniform;

          if (isVariableWidth) {
            _drawVariableWidthPoints(canvas, pathPoints, cached.bodyWidths, paint.color);
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
            final dir = startTangent.direction + pi;
            _drawEndpointShape(canvas, startArrowCenter, dir, resolved.startShape!, endpointColor.withAlpha(255), startMargin);
          }
          if (resolved.endShape != null && resolved.endShape != EndpointShape.none) {
            final dir = endTangent.direction;
            _drawEndpointShape(canvas, endArrowCenter, dir, resolved.endShape!, endpointColor.withAlpha(255), endMargin);
          }

          if (isSelected) {
            _drawSelectionHandles(canvas, start, end);
          }

          if (rel.verb.isNotEmpty) {
            _drawText(canvas, rel.verb, labelPos, paint.color, paint.strokeWidth);
          }
          continue;
        }

        final endpoints = resolveRelationEndpoints(rel, from, to);
        start = endpoints.$1;
        end = endpoints.$2;
        path = buildSimpleBezierPath(start, end);
        labelPos = Offset.lerp(start, end, 0.5)!;
      }

      final resolved = RelationStyleStrategy.resolveStyle(rel);
      final isSelected = selectedEntities.contains(rel.id);

      if (tipDrag != null) {
        paint.color = tipDrag.snappedTargetNodeId != null
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

      final strokePattern = resolved.strokePattern;
      if (strokePattern == 'dashed' || strokePattern == 'dotted') {
        canvas.drawPath(_createPatternedPath(path, strokePattern), paint);
      } else {
        canvas.drawPath(path, paint);
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
        _drawSelectionHandles(canvas, start, end);
      }

      if (rel.verb.isNotEmpty) {
        _drawText(canvas, rel.verb, labelPos, paint.color, paint.strokeWidth);
      }
    }
  }


  void _drawSelectionHandles(Canvas canvas, Offset start, Offset end) {
    final handlePaint = Paint()
      ..color = AppConfig.visuals.selectionAccent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(start, 6.0, borderPaint);
    canvas.drawCircle(start, 5.0, handlePaint);
    canvas.drawCircle(end, 6.0, borderPaint);
    canvas.drawCircle(end, 5.0, handlePaint);
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

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(direction);

    switch (shape) {
      case EndpointShape.none:
        break;
      case EndpointShape.arrow:
        final path = Path();
        path.moveTo(half, 0);
        path.lineTo(-half, -half);
        path.lineTo(-half, half);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case EndpointShape.openArrow:
        final path = Path();
        path.moveTo(half, 0);
        path.lineTo(-half, -half);
        path.moveTo(half, 0);
        path.lineTo(-half, half);
        canvas.drawPath(path, strokePaint);
        break;
      case EndpointShape.circle:
        canvas.drawCircle(Offset.zero, half, fillPaint);
        break;
      case EndpointShape.diamond:
        final path = Path();
        path.moveTo(0, -half);
        path.lineTo(half, 0);
        path.lineTo(0, half);
        path.lineTo(-half, 0);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case EndpointShape.square:
        final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    if (identical(oldDelegate.relations, relations) == false) return true;
    if (oldDelegate.selectedEntities != selectedEntities) return true;
    if (identical(oldDelegate.nodeViewStates, nodeViewStates) == false) return true;
    if (oldDelegate.interactionState != interactionState) return true;
    if (oldDelegate.theme != theme) return true;
    if (oldDelegate.relationEngine != relationEngine) return true;
    return false;
  }
}
