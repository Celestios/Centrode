import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/src/rust/relation_engine/config.dart' as rust_config;
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_query_controller.dart';
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
    final queryController = context.read<GraphDataQueryController>();
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
          queryController.relationEngine.cacheNotifier,
        ]),
        builder: (context, _) {
          final interactionState = interactionController.state.value;

          final activeEditId = uiController.activeEditId;
          final editedRel = activeEditId != null
              ? queryController.relations
                    .where((r) => r.id == activeEditId)
                    .firstOrNull
              : null;

          Widget? editorWidget;

          if (editedRel != null) {
            final cached = queryController.relationEngine.cache[editedRel.id];
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
            relations: queryController.relations.toList(),
            nodeViewStates: uiController.viewStates,
            selectedEntities: uiController.selectedEntities,
            relationEngine: queryController.relationEngine,
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

  Path _buildPathFromOffsets(List<Offset> points) {
    if (points.isEmpty) return Path();
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
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
              interactionState.relationId == rel.id)
          ? interactionState
          : null;

      final resolved = RelationStyleStrategy.resolveStyle(rel);
      final isSelected = selectedEntities.contains(rel.id);

      final color = _resolveColor(
        tipDrag: tipDrag,
        isSelected: isSelected,
        resolved: resolved,
        theme: theme,
      );
      final strokeWidth = _resolveStrokeWidth(
        tipDrag: tipDrag,
        isSelected: isSelected,
        resolved: resolved,
      );

      final Offset? dragPos;
      if (tipDrag != null) {
        if (tipDrag.snappedTargetNodeId != null && tipDrag.snappedTargetSide != null) {
          final targetVs = nodeViewStates[tipDrag.snappedTargetNodeId!];
          dragPos = targetVs != null
              ? targetVs.getPortPosition(tipDrag.snappedTargetSide!)
              : tipDrag.currentCursorPosition;
        } else {
          dragPos = tipDrag.currentCursorPosition;
        }
      } else {
        dragPos = null;
      }

      final cached = relationEngine?.cache[rel.id];
      if (cached != null && cached.pathPoints.isNotEmpty) {
        dtos.add(_buildCachedPaintDto(
          rel: rel,
          cached: cached,
          tipDrag: tipDrag,
          dragPos: dragPos,
          resolved: resolved,
          isSelected: isSelected,
          color: color,
          strokeWidth: strokeWidth,
        ));
      }
    }

    return dtos;
  }

  Color _resolveColor({
    required RelationTipDragging? tipDrag,
    required bool isSelected,
    required RelationStyle resolved,
    required ThemeData theme,
  }) {
    if (tipDrag != null) {
      return tipDrag.snappedTargetNodeId != null ? Colors.green : Colors.blueAccent;
    }
    if (isSelected) {
      return AppConfig.visuals.selectionAccent;
    }
    return Color(resolved.strokeColor);
  }

  double _resolveStrokeWidth({
    required RelationTipDragging? tipDrag,
    required bool isSelected,
    required RelationStyle resolved,
  }) {
    if (tipDrag != null || isSelected) {
      return AppConfig.relation.selectedStrokeWidth;
    }
    return resolved.strokeWidth.toDouble();
  }

  RelationPaintDto _buildCachedPaintDto({
    required UiRelation rel,
    required ComputedRelation cached,
    required RelationTipDragging? tipDrag,
    required Offset? dragPos,
    required RelationStyle resolved,
    required bool isSelected,
    required Color color,
    required double strokeWidth,
  }) {
    final s0 = Offset(cached.pathPoints.first.x, cached.pathPoints.first.y);
    final e0 = Offset(cached.pathPoints.last.x, cached.pathPoints.last.y);
    final startTangent = Offset(cached.startTangent.x, cached.startTangent.y);
    final endTangent = Offset(cached.endTangent.x, cached.endTangent.y);

    final Offset targetStart;
    final Offset targetEnd;

    if (tipDrag != null && dragPos != null) {
      targetStart = tipDrag.isStartTip ? dragPos : Offset(cached.startPoint.x, cached.startPoint.y);
      targetEnd = !tipDrag.isStartTip ? dragPos : Offset(cached.endPoint.x, cached.endPoint.y);
    } else {
      targetStart = Offset(cached.startPoint.x, cached.startPoint.y);
      targetEnd = Offset(cached.endPoint.x, cached.endPoint.y);
    }

    final startWidth = cached.bodyWidths.isNotEmpty ? cached.bodyWidths.first : resolved.strokeWidth.toDouble();
    final endWidth = cached.bodyWidths.isNotEmpty ? cached.bodyWidths.last : resolved.strokeWidth.toDouble();
    final startScale = startWidth > 0.0 ? startWidth / 2.0 : 1.0;
    final endScale = endWidth > 0.0 ? endWidth / 2.0 : 1.0;

    final startArrowMargin = (resolved.startShape != null && resolved.startShape != EndpointShape.none)
        ? resolved.arrowSize * startScale
        : 0.0;
    final endArrowMargin = (resolved.endShape != null && resolved.endShape != EndpointShape.none)
        ? resolved.arrowSize * endScale
        : 0.0;

    final start = targetStart + startTangent * (startArrowMargin * 0.5);
    final end = targetEnd - endTangent * (endArrowMargin * 0.5);

    final pointsOffset = cached.pathPoints.map((p) => Offset(p.x, p.y)).toList();
    final transformedPoints = transformPathPoints(
      points: pointsOffset,
      sourceStart: s0,
      sourceEnd: e0,
      targetStart: start,
      targetEnd: end,
    );



    final path = _buildPathFromOffsets(transformedPoints);

    final p0Label = Offset(cached.labelPosition.x, cached.labelPosition.y);
    final labelTransformedList = transformPathPoints(
      points: [p0Label],
      sourceStart: s0,
      sourceEnd: e0,
      targetStart: start,
      targetEnd: end,
    );
    final labelPos = labelTransformedList.isNotEmpty ? labelTransformedList.first : Offset.lerp(start, end, 0.5)!;

    return RelationPaintDto(
      id: rel.id,
      path: path,
      points: transformedPoints,
      widths: cached.bodyWidths,
      isVariableWidth: cached.bodyType != rust_config.BodyType.uniform,
      color: color,
      strokeWidth: strokeWidth,
      strokePattern: resolved.strokePattern,
      startShape: resolved.startShape,
      endShape: resolved.endShape,
      arrowSize: resolved.arrowSize,
      startArrowCenter: Offset(cached.startArrowCenter.x, cached.startArrowCenter.y),
      endArrowCenter: Offset(cached.endArrowCenter.x, cached.endArrowCenter.y),
      startArrowDirection: cached.startDirection,
      endArrowDirection: cached.endDirection,
      startArrowMargin: startArrowMargin,
      endArrowMargin: endArrowMargin,
      isSelected: isSelected,
      startPoint: targetStart,
      endPoint: targetEnd,
      verb: rel.verb,
      labelPos: labelPos,
    );
  }
}
