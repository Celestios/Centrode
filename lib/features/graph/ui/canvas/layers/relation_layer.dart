import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/relation_engine/config.dart' as rust_config;
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_query_controller.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../painters/relation_painter.dart';
import '../painters/relation_painter_dto.dart';
import '../text/canvas_text_editor.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import '../../../presentation/workspace_tabs_controller.dart';
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
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
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
          session.relationLabelModeNotifier,
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
              final labelPos = Offset(
                cached.labelPosition.x,
                cached.labelPosition.y,
              );
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
                      color: AppThemeManager.instance.currentTheme.canvasAccentColor,
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
            labelMode: session.relationLabelModeNotifier.value,
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
    required String labelMode,
    required ThemeData theme,
  }) {
    final List<RelationPaintDto> dtos = [];

    for (final rel in relations) {
      final from = nodeViewStates[rel.fromNodeId];
      final to = nodeViewStates[rel.toNodeId];

      if (from == null || to == null) continue;

      final tipDrag =
          (interactionState is RelationTipDragging &&
              interactionState.relationId == rel.id)
          ? interactionState
          : null;

      final resolved = RelationStyleStrategy.resolveStyle(rel);
      final isSelected = selectedEntities.contains(rel.id);
      final showLabel = switch (labelMode) {
        'never' => false,
        'always' => true,
        'auto' => isSelected,
        _ => isSelected,
      };

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
        if (tipDrag.snappedTargetNodeId != null &&
            tipDrag.snappedTargetSide != null) {
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

      final bool isNodeDragging =
          (interactionState is NodeDragging &&
              (interactionState.nodeId == rel.fromNodeId ||
                  interactionState.nodeId == rel.toNodeId)) ||
          (interactionState is GroupDragging &&
              (interactionState.nodeIds.contains(rel.fromNodeId) ||
                  interactionState.nodeIds.contains(rel.toNodeId))) ||
          (interactionState is NodeResizing &&
              (interactionState.nodeId == rel.fromNodeId ||
                  interactionState.nodeId == rel.toNodeId));

      final previewCached = relationEngine?.previewCache[rel.id];
      final usePreview =
          tipDrag != null &&
          tipDrag.snappedTargetNodeId != null &&
          previewCached != null;

      if (usePreview) {
        dtos.add(
          _buildPreviewPaintDto(
            rel: rel,
            cached: previewCached,
            tipDrag: tipDrag,
            dragPos: dragPos,
            fromVs: from,
            toVs: to,
            resolved: resolved,
            isSelected: isSelected,
            showLabel: showLabel,
            color: color,
            strokeWidth: strokeWidth,
          ),
        );
      } else {
        final cached = relationEngine?.cache[rel.id];
        if (cached != null && cached.pathPoints.isNotEmpty) {
          dtos.add(
            _buildCachedPaintDto(
              rel: rel,
              cached: cached,
              tipDrag: tipDrag,
              dragPos: dragPos,
              isNodeDragging: isNodeDragging,
              fromVs: from,
              toVs: to,
              resolved: resolved,
              isSelected: isSelected,
              showLabel: showLabel,
              color: color,
              strokeWidth: strokeWidth,
            ),
          );
        }
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
      return tipDrag.snappedTargetNodeId != null
          ? Colors.green
          : Colors.blueAccent;
    }
    if (isSelected) {
      return AppThemeManager.instance.currentTheme.canvasAccentColor;
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
    required bool isNodeDragging,
    required NodeViewState fromVs,
    required NodeViewState toVs,
    required RelationStyle resolved,
    required bool isSelected,
    required bool showLabel,
    required Color color,
    required double strokeWidth,
  }) {
    final bool isDraggingThisTip = tipDrag != null && dragPos != null;

    final rawStart = Offset(cached.startPoint.x, cached.startPoint.y);
    final rawEnd = Offset(cached.endPoint.x, cached.endPoint.y);

    final fromSide = rel.resolvedLayout?.fromSide ?? rel.layout?.fromSide;
    final toSide = rel.resolvedLayout?.toSide ?? rel.layout?.toSide;
    final liveStart = fromSide != null
        ? fromVs.getPortPosition(fromSide)
        : fromVs.getClosestPort(rawEnd).position;
    final liveEnd = toSide != null
        ? toVs.getPortPosition(toSide)
        : toVs.getClosestPort(rawStart).position;

    final bool isReversedCache =
        (rawStart - liveEnd).distance < (rawStart - liveStart).distance &&
        (rawEnd - liveStart).distance < (rawEnd - liveEnd).distance;

    final startPoint = isReversedCache ? rawEnd : rawStart;
    final endPoint = isReversedCache ? rawStart : rawEnd;

    final List<Point> cachedPathPoints = isReversedCache
        ? cached.pathPoints.reversed.toList()
        : cached.pathPoints;
    final List<Point> cachedStartShape = isReversedCache
        ? cached.endShapePath
        : cached.startShapePath;
    final List<Point> cachedEndShape = isReversedCache
        ? cached.startShapePath
        : cached.endShapePath;
    final Point cachedStartHandle = isReversedCache
        ? cached.endHandlePos
        : cached.startHandlePos;
    final Point cachedEndHandle = isReversedCache
        ? cached.startHandlePos
        : cached.endHandlePos;

    final bool isCacheStale =
        (startPoint - liveStart).distance > 0.5 ||
        (endPoint - liveEnd).distance > 0.5;
    final bool needsTransform =
        isDraggingThisTip || isNodeDragging || isCacheStale;

    final List<Offset> bodyPoints;
    final List<Offset> startShapeVertices;
    final List<Offset> endShapeVertices;
    final Offset labelPos;
    final Offset startHandlePos;
    final Offset endHandlePos;
    final Offset startPointResult;
    final Offset endPointResult;

    if (needsTransform) {
      final Offset transformStart = isDraggingThisTip && tipDrag.isStartTip
          ? dragPos
          : liveStart;
      final Offset transformEnd = isDraggingThisTip && !tipDrag.isStartTip
          ? dragPos
          : liveEnd;

      List<Offset> transform(List<Point> pts) => transformPathPoints(
        points: pts.map((p) => Offset(p.x, p.y)).toList(),
        sourceStart: startPoint,
        sourceEnd: endPoint,
        targetStart: transformStart,
        targetEnd: transformEnd,
      );

      bodyPoints = transform(cachedPathPoints);
      startShapeVertices = cachedStartShape.isNotEmpty
          ? transform(cachedStartShape)
          : const [];
      endShapeVertices = cachedEndShape.isNotEmpty
          ? transform(cachedEndShape)
          : const [];

      final labelTransformed = transform([
        Point(x: cached.labelPosition.x, y: cached.labelPosition.y),
      ]);
      labelPos = labelTransformed.isNotEmpty
          ? labelTransformed.first
          : Offset.lerp(transformStart, transformEnd, 0.5)!;

      final handlesTransformed = transform([
        Point(x: cachedStartHandle.x, y: cachedStartHandle.y),
        Point(x: cachedEndHandle.x, y: cachedEndHandle.y),
      ]);
      startHandlePos = isDraggingThisTip
          ? transformStart
          : (handlesTransformed.isNotEmpty ? handlesTransformed.first : transformStart);
      endHandlePos = isDraggingThisTip
          ? transformEnd
          : (handlesTransformed.length > 1 ? handlesTransformed.last : transformEnd);
      startPointResult = transformStart;
      endPointResult = transformEnd;
    } else {
      bodyPoints = cachedPathPoints.map((p) => Offset(p.x, p.y)).toList();
      startShapeVertices = cachedStartShape.isNotEmpty
          ? cachedStartShape.map((p) => Offset(p.x, p.y)).toList()
          : const [];
      endShapeVertices = cachedEndShape.isNotEmpty
          ? cachedEndShape.map((p) => Offset(p.x, p.y)).toList()
          : const [];
      labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);
      startHandlePos = Offset(cachedStartHandle.x, cachedStartHandle.y);
      endHandlePos = Offset(cachedEndHandle.x, cachedEndHandle.y);
      startPointResult = startPoint;
      endPointResult = endPoint;
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
      startPoint: startPointResult,
      endPoint: endPointResult,
      startHandlePos: startHandlePos,
      endHandlePos: endHandlePos,
      isDragging: isDraggingThisTip,
      verb: showLabel ? rel.verb : '',
      labelPos: labelPos,
      widths: cached.bodyWidths,
      isVariableWidth: cached.bodyType != rust_config.BodyType.uniform,
    );
  }

  RelationPaintDto _buildPreviewPaintDto({
    required UiRelation rel,
    required ComputedRelation cached,
    required RelationTipDragging? tipDrag,
    required Offset? dragPos,
    required NodeViewState fromVs,
    required NodeViewState toVs,
    required RelationStyle resolved,
    required bool isSelected,
    required bool showLabel,
    required Color color,
    required double strokeWidth,
  }) {
    final bodyPoints = cached.pathPoints.map((p) => Offset(p.x, p.y)).toList();
    final startShapeVertices = cached.startShapePath.isNotEmpty
        ? cached.startShapePath.map((p) => Offset(p.x, p.y)).toList()
        : const <Offset>[];
    final endShapeVertices = cached.endShapePath.isNotEmpty
        ? cached.endShapePath.map((p) => Offset(p.x, p.y)).toList()
        : const <Offset>[];
    final labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);
    final startHandlePos = Offset(
      cached.startHandlePos.x,
      cached.startHandlePos.y,
    );
    final endHandlePos = Offset(cached.endHandlePos.x, cached.endHandlePos.y);
    final startPoint = Offset(cached.startPoint.x, cached.startPoint.y);
    final endPoint = Offset(cached.endPoint.x, cached.endPoint.y);

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
      startPoint: startPoint,
      endPoint: endPoint,
      startHandlePos: startHandlePos,
      endHandlePos: endHandlePos,
      isDragging: true,
      verb: showLabel ? rel.verb : '',
      labelPos: labelPos,
      widths: cached.bodyWidths,
      isVariableWidth: cached.bodyType != rust_config.BodyType.uniform,
    );
  }
}
