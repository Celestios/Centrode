import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/relation_engine/config.dart' as rust_config;
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/domain/routing.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../engine/config.dart';
import '../../../models/models.dart';
import '../../../presentation/view_state.dart';
import '../../../presentation/strategies/relation_style_strategy.dart';
import '../../../presentation/relation_utils.dart';
import '../../../store/relation_engine_state.dart';
import '../../../engine/base_interaction_state.dart';
import 'relation_painter_dto.dart';

class RelationPaintDtoBuilder {
  static List<RelationPaintDto> buildPaintDtos({
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

      final color = resolveColor(
        tipDrag: tipDrag,
        isSelected: isSelected,
        resolved: resolved,
        theme: theme,
      );
      final strokeWidth = resolveStrokeWidth(
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
          buildPreviewPaintDto(
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
            buildCachedPaintDto(
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

  static Color resolveColor({
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

  static double resolveStrokeWidth({
    required RelationTipDragging? tipDrag,
    required bool isSelected,
    required RelationStyle resolved,
  }) {
    if (tipDrag != null || isSelected) {
      return AppConfig.relation.selectedStrokeWidth;
    }
    return resolved.strokeWidth.toDouble();
  }

  static RelationPaintDto buildCachedPaintDto({
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

    final fromSide =
        (rel.resolvedLayout?.fromSide != null &&
            rel.resolvedLayout!.fromSide != PortSide.auto)
        ? rel.resolvedLayout!.fromSide
        : (rel.layout?.fromSide != null &&
                rel.layout!.fromSide != PortSide.auto)
            ? rel.layout!.fromSide
            : null;

    final toSide =
        (rel.resolvedLayout?.toSide != null &&
            rel.resolvedLayout!.toSide != PortSide.auto)
        ? rel.resolvedLayout!.toSide
        : (rel.layout?.toSide != null &&
                rel.layout!.toSide != PortSide.auto)
            ? rel.layout!.toSide
            : null;

    final liveStart = fromSide != null
        ? fromVs.getPortPosition(fromSide)
        : fromVs.getClosestPort(startPoint).position;

    final liveEnd = toSide != null
        ? toVs.getPortPosition(toSide)
        : toVs.getClosestPort(endPoint).position;

    final bool needsTransform =
        isDraggingThisTip ||
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
          : (handlesTransformed.isNotEmpty
              ? handlesTransformed.first
              : transformStart);
      endHandlePos = isDraggingThisTip
          ? transformEnd
          : (handlesTransformed.length > 1
              ? handlesTransformed.last
              : transformEnd);
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

  static RelationPaintDto buildPreviewPaintDto({
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
