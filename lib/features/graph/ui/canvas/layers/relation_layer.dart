import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'package:mycelium/src/rust/relation_engine/config.dart' as rust_config;
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import 'package:mycelium/src/rust/relation_engine/geometry.dart';
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

  List<RelationPaintDto> _buildPaintDtos({
    required List<UiRelation> relations,
    required Map<RawUuid, NodeViewState> nodeViewStates,
    required Set<RawUuid> selectedEntities,
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
          fromVs: from,
          toVs: to,
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
    required NodeViewState fromVs,
    required NodeViewState toVs,
    required RelationStyle resolved,
    required bool isSelected,
    required Color color,
    required double strokeWidth,
  }) {
    final bool isDraggingThisTip = tipDrag != null && dragPos != null;
    final startPoint = Offset(cached.startPoint.x, cached.startPoint.y);
    final endPoint = Offset(cached.endPoint.x, cached.endPoint.y);

    final fromSide = rel.resolvedLayout?.fromSide ?? rel.layout?.fromSide;
    final toSide = rel.resolvedLayout?.toSide ?? rel.layout?.toSide;

    final Offset liveStart = fromSide != null
        ? fromVs.getPortPosition(fromSide)
        : fromVs.getClosestPort(endPoint).position;

    final Offset liveEnd = toSide != null
        ? toVs.getPortPosition(toSide)
        : toVs.getClosestPort(startPoint).position;

    final Offset targetStart = isDraggingThisTip
        ? (tipDrag.isStartTip ? dragPos : startPoint)
        : liveStart;

    final Offset targetEnd = isDraggingThisTip
        ? (!tipDrag.isStartTip ? dragPos : endPoint)
        : liveEnd;

    final bool needsTransform = isDraggingThisTip ||
        (targetStart - startPoint).distanceSquared > 1e-4 ||
        (targetEnd - endPoint).distanceSquared > 1e-4;

    final List<Offset> bodyPoints;
    final List<Offset> startShapeVertices;
    final List<Offset> endShapeVertices;
    final Offset labelPos;
    final Offset startHandlePos;
    final Offset endHandlePos;

    if (needsTransform) {
      final s0 = startPoint;
      final e0 = endPoint;

      List<Offset> transform(List<Point> pts) => transformPathPoints(
        points: pts.map((p) => Offset(p.x, p.y)).toList(),
        sourceStart: s0,
        sourceEnd: e0,
        targetStart: targetStart,
        targetEnd: targetEnd,
      );

      bodyPoints = transform(cached.pathPoints);
      startShapeVertices = cached.startShapePath.isNotEmpty
          ? transform(cached.startShapePath)
          : const [];
      endShapeVertices = cached.endShapePath.isNotEmpty
          ? transform(cached.endShapePath)
          : const [];

      final labelTransformed = transform([Point(x: cached.labelPosition.x, y: cached.labelPosition.y)]);
      labelPos = labelTransformed.isNotEmpty
          ? labelTransformed.first
          : Offset.lerp(targetStart, targetEnd, 0.5)!;

      startHandlePos = targetStart;
      endHandlePos = targetEnd;
    } else {
      bodyPoints = cached.pathPoints.map((p) => Offset(p.x, p.y)).toList();
      startShapeVertices = cached.startShapePath.isNotEmpty
          ? cached.startShapePath.map((p) => Offset(p.x, p.y)).toList()
          : const [];
      endShapeVertices = cached.endShapePath.isNotEmpty
          ? cached.endShapePath.map((p) => Offset(p.x, p.y)).toList()
          : const [];
      labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);
      startHandlePos = Offset(cached.startHandlePos.x, cached.startHandlePos.y);
      endHandlePos = Offset(cached.endHandlePos.x, cached.endHandlePos.y);
    }

    return RelationPaintDto(
      id: rel.id,
      bodyPoints: bodyPoints,
      startShapeVertices: startShapeVertices,
      endShapeVertices: endShapeVertices,
      startShapeFilled: cached.startShapeFilled,
      endShapeFilled: cached.endShapeFilled,
      color: color,
      strokeWidth: strokeWidth,
      strokePattern: resolved.strokePattern,
      isSelected: isSelected,
      startPoint: targetStart,
      endPoint: targetEnd,
      startHandlePos: startHandlePos,
      endHandlePos: endHandlePos,
      isDragging: isDraggingThisTip,
      verb: rel.verb,
      labelPos: labelPos,
      widths: cached.bodyWidths,
      isVariableWidth: cached.bodyType != rust_config.BodyType.uniform,
    );
  }
}
