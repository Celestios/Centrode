import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart' as rust_config;
import 'package:mycelium/src/rust/domain/relation_engine/geometry.dart' as rust_geom;
import '../../../engine/config.dart';
import '../../../store/graph_data_controller.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../painters/relation_painter.dart';
import '../painters/relation_painter_dto.dart';
import '../text/canvas_text_editor.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';
import '../../../presentation/view_state.dart';
import '../../../presentation/strategies/relation_style_strategy.dart';
import '../../../presentation/relation_utils.dart';
import '../../../store/relation_engine_state.dart';
import '../../../engine/base_interaction_state.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataController>();
    final uiController = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          uiController.movementNotifier,
          uiController.selectionState,
          uiController.relationDataNotifier,
          uiController.editorState,
          interactionController.state,
          dataController.relationEngine.cacheNotifier,
        ]),
        builder: (context, _) {
          final interactionState = interactionController.state.value;

          final activeEditId = uiController.activeEditId;
          final editedRel = activeEditId != null
              ? dataController.relations
                    .where((r) => r.id == activeEditId)
                    .firstOrNull
              : null;

          Widget? editorWidget;

          if (editedRel != null) {
            final cached = dataController.relationEngine.cache[editedRel.id];
            if (cached != null) {
              final labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);
              final width = AppConfig.relation.editorMinWidth;
              final position =
                  labelPos -
                  Offset(width / 2, AppConfig.relation.editorVerticalOffset);

              editorWidget = Positioned(
                left: position.dx,
                top: position.dy,
                child: Container(
                  width: AppConfig.relation.editorMinWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.relation.editorBgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppConfig.visuals.selectionAccent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CanvasTextEditor(
                    entityId: editedRel.id,
                    content: ContentFactory.fromText(editedRel.verb),
                    maxLines: 1,
                    textStyle: TextStyle(
                      fontSize: AppConfig.editor.fontSizeRelation,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            }
          }

          final paintDtos = _buildPaintDtos(
            relations: dataController.relations.toList(),
            nodeViewStates: uiController.viewStates,
            selectedEntities: uiController.selectedEntities,
            relationEngine: dataController.relationEngine,
            interactionState: interactionState,
            theme: theme,
          );

          return UnboundedStack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: RelationPainter(
                      paintDtos: paintDtos,
                      theme: theme,
                    ),
                  ),
                ),
              ),
              if (editorWidget != null) editorWidget,
            ],
          );
        },
      ),
    );
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

  List<RelationPaintDto> _buildPaintDtos({
    required List<UiRelation> relations,
    required Map<String, NodeViewState> nodeViewStates,
    required Set<String> selectedEntities,
    required CanvasInteractionState? interactionState,
    required RelationEngineState? relationEngine,
    required ThemeData theme,
  }) {
    final List<RelationPaintDto> dtos = [];

    for (final rel in relations) {
      final from = nodeViewStates[rel.fromNodeId];
      final to = nodeViewStates[rel.toNodeId];

      if (from == null || to == null) continue;

      final tipDrag = (interactionState is RelationTipDragging &&
              (interactionState as RelationTipDragging).relationId == rel.id)
          ? interactionState as RelationTipDragging
          : null;

      Offset start;
      Offset end;
      Path path;
      Offset labelPos;
      List<Offset> points = [];
      List<double> widths = [];
      bool isVariableWidth = false;
      Color color;
      double strokeWidth;
      String strokePattern;
      EndpointShape? startShape;
      EndpointShape? endShape;
      double arrowSize;
      Offset startArrowCenter;
      Offset endArrowCenter;
      double startArrowDirection;
      double endArrowDirection;
      double startArrowMargin;
      double endArrowMargin;

      final resolved = RelationStyleStrategy.resolveStyle(rel);
      final isSelected = selectedEntities.contains(rel.id);

      if (tipDrag != null) {
        final Offset dragPos;
        if (tipDrag.snappedTargetNodeId != null && tipDrag.snappedTargetSide != null) {
          final targetVs = nodeViewStates[tipDrag.snappedTargetNodeId!];
          dragPos = targetVs != null
              ? targetVs.getPortPosition(tipDrag.snappedTargetSide!)
              : tipDrag.currentCursorPosition;
        } else {
          dragPos = tipDrag.currentCursorPosition;
        }

        final endpoints = resolveRelationEndpoints(
          rel, from, to,
          overrideStart: tipDrag.isStartTip ? dragPos : null,
          overrideEnd: !tipDrag.isStartTip ? dragPos : null,
        );
        start = endpoints.$1;
        end = endpoints.$2;
        path = buildSimpleBezierPath(start, end);
        labelPos = Offset.lerp(start, end, 0.5)!;

        points = [start, end];
        widths = [resolved.strokeWidth.toDouble(), resolved.strokeWidth.toDouble()];
        isVariableWidth = false;

        color = tipDrag.snappedTargetNodeId != null ? Colors.green : Colors.blueAccent;
        strokeWidth = AppConfig.relation.selectedStrokeWidth;
        strokePattern = resolved.strokePattern;

        startShape = resolved.startShape;
        endShape = resolved.endShape;
        arrowSize = resolved.arrowSize;

        final fromCenter = from.rect.center;
        final outwardStartDir = (start - fromCenter).direction;
        final startOffset = Offset(cos(outwardStartDir), sin(outwardStartDir)) * resolved.arrowSize * 0.5;
        startArrowCenter = start + startOffset;
        startArrowDirection = outwardStartDir + pi;
        startArrowMargin = resolved.arrowSize;

        final toCenter = to.rect.center;
        final outwardEndDir = (end - toCenter).direction;
        final endOffset = Offset(cos(outwardEndDir), sin(outwardEndDir)) * resolved.arrowSize * 0.5;
        endArrowCenter = end + endOffset;
        endArrowDirection = outwardEndDir + pi;
        endArrowMargin = resolved.arrowSize;
      } else {
        final cached = relationEngine?.cache[rel.id];
        if (cached != null && cached.pathPoints.isNotEmpty) {
          final Offset s0 = Offset(cached.pathPoints.first.x, cached.pathPoints.first.y);
          final Offset e0 = Offset(cached.pathPoints.last.x, cached.pathPoints.last.y);

          final String stateStr = interactionState?.runtimeType.toString() ?? '';
          final bool isDragging = stateStr.contains('Drag') || stateStr.contains('Dragging');

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

          List<rust_geom.Point> pathPoints;

          if (isDragging) {
            final currentEndpoints = resolveRelationEndpoints(rel, from, to);
            final currentStart = currentEndpoints.$1;
            final currentEnd = currentEndpoints.$2;

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
          points = pathPoints.map((p) => Offset(p.x, p.y)).toList();
          widths = cached.bodyWidths;
          isVariableWidth = cached.bodyType != rust_config.BodyType.uniform;

          color = isSelected
              ? AppConfig.visuals.selectionAccent
              : Color(resolved.strokeColor);
          strokeWidth = isSelected
              ? AppConfig.relation.selectedStrokeWidth
              : resolved.strokeWidth.toDouble();
          strokePattern = resolved.strokePattern;

          startShape = resolved.startShape;
          endShape = resolved.endShape;
          arrowSize = resolved.arrowSize;

          startArrowDirection = startTangent.direction + pi;
          endArrowDirection = endTangent.direction;
          startArrowMargin = startMargin;
          endArrowMargin = endMargin;
        } else {
          final endpoints = resolveRelationEndpoints(rel, from, to);
          start = endpoints.$1;
          end = endpoints.$2;
          path = buildSimpleBezierPath(start, end);
          labelPos = Offset.lerp(start, end, 0.5)!;

          points = [start, end];
          widths = [resolved.strokeWidth.toDouble(), resolved.strokeWidth.toDouble()];
          isVariableWidth = false;

          color = isSelected
              ? AppConfig.visuals.selectionAccent
              : Color(resolved.strokeColor);
          strokeWidth = isSelected
              ? AppConfig.relation.selectedStrokeWidth
              : resolved.strokeWidth.toDouble();
          strokePattern = resolved.strokePattern;

          startShape = resolved.startShape;
          endShape = resolved.endShape;
          arrowSize = resolved.arrowSize;

          final fromCenter = from.rect.center;
          final outwardStartDir = (start - fromCenter).direction;
          final startOffset = Offset(cos(outwardStartDir), sin(outwardStartDir)) * resolved.arrowSize * 0.5;
          startArrowCenter = start + startOffset;
          startArrowDirection = outwardStartDir + pi;
          startArrowMargin = resolved.arrowSize;

          final toCenter = to.rect.center;
          final outwardEndDir = (end - toCenter).direction;
          final endOffset = Offset(cos(outwardEndDir), sin(outwardEndDir)) * resolved.arrowSize * 0.5;
          endArrowCenter = end + endOffset;
          endArrowDirection = outwardEndDir + pi;
          endArrowMargin = resolved.arrowSize;
        }
      }

      dtos.add(RelationPaintDto(
        id: rel.id,
        path: path,
        points: points,
        widths: widths,
        isVariableWidth: isVariableWidth,
        color: color,
        strokeWidth: strokeWidth,
        strokePattern: strokePattern,
        startShape: startShape,
        endShape: endShape,
        arrowSize: arrowSize,
        startArrowCenter: startArrowCenter,
        endArrowCenter: endArrowCenter,
        startArrowDirection: startArrowDirection,
        endArrowDirection: endArrowDirection,
        startArrowMargin: startArrowMargin,
        endArrowMargin: endArrowMargin,
        isSelected: isSelected,
        startPoint: start,
        endPoint: end,
        verb: rel.verb,
        labelPos: labelPos,
      ));
    }

    return dtos;
  }
}
