import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/relation_engine/config.dart' as rust_config;
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' hide Rect;
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
import '../../../presentation/strategies/node_layout_strategy.dart';
import '../../../presentation/relation_utils.dart';
import '../../../store/relation_engine_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../presentation/viewport_state.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final queryController = context.read<GraphDataQueryController>();
    final uiController = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();
    final viewport = context.read<ViewportController>();
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
          viewport.activeScopeNotifier,
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

          final activeScope = viewport.activeScopeNotifier.value;
          final scopeRelations = queryController.relationsInScope(activeScope);

          final paintDtos = _buildPaintDtos(
            relations: scopeRelations,
            nodeViewStates: uiController.viewStates,
            selectedEntities: uiController.selectedEntities,
            relationEngine: queryController.relationEngine,
            interactionState: interactionState,
            labelMode: session.relationLabelModeNotifier.value,
            theme: theme,
          );

          List<RelationPaintDto> outsidePaintDtos = const [];
          double outsideScaleX = 1.0;
          double outsideScaleY = 1.0;
          Offset outsideOriginOffset = Offset.zero;

          if (activeScope is ContainerViewportScope) {
            final parentContainer = queryController.nodeLookup[activeScope.containerId] as ContainerUiNode?;
            final containerVs = uiController.viewStates[activeScope.containerId];
            final effectiveOuterSize = (containerVs != null && containerVs.sizeNotifier.value.width > 0 && containerVs.sizeNotifier.value.height > 0)
                ? Size(containerVs.dragWidthNotifier.value ?? containerVs.sizeNotifier.value.width, containerVs.sizeNotifier.value.height)
                : (activeScope.outerSize.width > 0 && activeScope.outerSize.height > 0)
                    ? activeScope.outerSize
                    : (parentContainer != null)
                        ? const DefaultNodeLayoutStrategy().calculateSize(parentContainer).size
                        : const Size(300.0, 180.0);
            outsideOriginOffset = containerVs?.positionNotifier.value ?? parentContainer?.position ?? activeScope.containerPositionInParent;
            final aspectRatio = effectiveOuterSize.height / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
            final internalW = 1600.0;
            final internalH = 1600.0 * aspectRatio;
            outsideScaleX = internalW / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
            outsideScaleY = internalH / (effectiveOuterSize.height > 0 ? effectiveOuterSize.height : 1.0);

            final parentScope = activeScope.parentScope ?? const RootViewportScope();
            final outsideRelations = queryController.relationsInScope(parentScope);
            outsidePaintDtos = _buildPaintDtos(
              relations: outsideRelations,
              nodeViewStates: uiController.viewStates,
              selectedEntities: uiController.selectedEntities,
              relationEngine: queryController.relationEngine,
              interactionState: interactionState,
              labelMode: session.relationLabelModeNotifier.value,
              theme: theme,
            );
          }

          return UnboundedStack(
            clipBehavior: Clip.none,
            children: [
              if (outsidePaintDtos.isNotEmpty)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _TransformedRelationPainter(
                        paintDtos: outsidePaintDtos,
                        theme: theme,
                        scaleX: outsideScaleX,
                        scaleY: outsideScaleY,
                        originOffset: outsideOriginOffset,
                      ),
                    ),
                  ),
                ),
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

    final startPoint = Offset(cached.startPoint.x, cached.startPoint.y);
    final endPoint = Offset(cached.endPoint.x, cached.endPoint.y);

    final fromSide = (rel.resolvedLayout?.fromSide != null &&
            rel.resolvedLayout!.fromSide != PortSide.auto)
        ? rel.resolvedLayout!.fromSide
        : (rel.layout?.fromSide != null &&
                rel.layout!.fromSide != PortSide.auto)
            ? rel.layout!.fromSide
            : null;

    final toSide = (rel.resolvedLayout?.toSide != null &&
            rel.resolvedLayout!.toSide != PortSide.auto)
        ? rel.resolvedLayout!.toSide
        : (rel.layout?.toSide != null && rel.layout!.toSide != PortSide.auto)
            ? rel.layout!.toSide
            : null;

    final liveStart = fromSide != null
        ? fromVs.getPortPosition(fromSide)
        : fromVs.getClosestPort(startPoint).position;

    final liveEnd = toSide != null
        ? toVs.getPortPosition(toSide)
        : toVs.getClosestPort(endPoint).position;

    final bool needsTransform = isDraggingThisTip ||
        isNodeDragging ||
        (liveStart - startPoint).distance > 0.5 ||
        (liveEnd - endPoint).distance > 0.5;

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

      bodyPoints = transform(cached.pathPoints);
      startShapeVertices = cached.startShapePath.isNotEmpty
          ? transform(cached.startShapePath)
          : const [];
      endShapeVertices = cached.endShapePath.isNotEmpty
          ? transform(cached.endShapePath)
          : const [];

      final labelTransformed = transform([
        Point(x: cached.labelPosition.x, y: cached.labelPosition.y),
      ]);
      labelPos = labelTransformed.isNotEmpty
          ? labelTransformed.first
          : Offset.lerp(transformStart, transformEnd, 0.5)!;

      final handlesTransformed = transform([
        Point(x: cached.startHandlePos.x, y: cached.startHandlePos.y),
        Point(x: cached.endHandlePos.x, y: cached.endHandlePos.y),
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

/// Bidirectional line segment intersection with a Container Rect.
/// Correctly computes perimeter intersection regardless of whether ray moves from inside->outside or outside->inside.
Offset calculateContainerPerimeterDock(RRect containerRRect, Offset pStart, Offset pEnd) {
  final rect = containerRRect.outerRect;
  final dir = (pEnd - pStart);
  if (dir == Offset.zero) return rect.center;

  return _intersectSegmentBox(rect, pStart, pEnd);
}

Offset _intersectSegmentBox(Rect rect, Offset pStart, Offset pEnd) {
  final dir = pEnd - pStart;
  double tMin = 0.0;
  double tMax = 1.0;

  if (dir.dx != 0.0) {
    final tx1 = (rect.left - pStart.dx) / dir.dx;
    final tx2 = (rect.right - pStart.dx) / dir.dx;
    tMin = (tMin > (tx1 < tx2 ? tx1 : tx2)) ? tMin : (tx1 < tx2 ? tx1 : tx2);
    tMax = (tMax < (tx1 > tx2 ? tx1 : tx2)) ? tMax : (tx1 > tx2 ? tx1 : tx2);
  }
  if (dir.dy != 0.0) {
    final ty1 = (rect.top - pStart.dy) / dir.dy;
    final ty2 = (rect.bottom - pStart.dy) / dir.dy;
    tMin = (tMin > (ty1 < ty2 ? ty1 : ty2)) ? tMin : (ty1 < ty2 ? ty1 : ty2);
    tMax = (tMax < (ty1 > ty2 ? ty1 : ty2)) ? tMax : (ty1 > ty2 ? ty1 : ty2);
  }

  if (tMin > tMax) return pEnd;

  final bool isStartInside = rect.contains(pStart);
  final double tBoundary = isStartInside ? tMax : tMin;

  final clampedT = tBoundary.clamp(0.0, 1.0);
  return pStart + (dir * clampedT);
}

class _TransformedRelationPainter extends CustomPainter {
  final List<RelationPaintDto> paintDtos;
  final ThemeData theme;
  final double scaleX;
  final double scaleY;
  final Offset originOffset;

  _TransformedRelationPainter({
    required this.paintDtos,
    required this.theme,
    required this.scaleX,
    required this.scaleY,
    required this.originOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paintDtos.isEmpty) return;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.translate(-originOffset.dx, -originOffset.dy);
    final painter = RelationPainter(paintDtos: paintDtos, theme: theme);
    painter.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TransformedRelationPainter oldDelegate) {
    return oldDelegate.paintDtos != paintDtos ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.originOffset != originOffset ||
        oldDelegate.theme != theme;
  }
}
