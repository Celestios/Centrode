part of '../base_interaction_state.dart';

class RelationDrawing extends CanvasInteractionState {
  final Set<RawUuid> sourceNodeIds;
  final Offset currentCursorPosition;
  final RawUuid? snappedTargetNodeId;
  final Port? sourcePort;
  final Port? snappedTargetPort;

  const RelationDrawing(
    this.sourceNodeIds,
    this.currentCursorPosition, {
    this.snappedTargetNodeId,
    this.sourcePort,
    this.snappedTargetPort,
  });

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
    bool isDoubleTap,
  ) {
    return this;
  }

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = ctx.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = ctx.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            ctx.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }

    ctx.setHoveredNode(hoveredNodeId);
    ctx.onNodeDragUpdate();
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      snappedTargetNodeId: snappedId,
      sourcePort: sourcePort,
      snappedTargetPort: snappedPort,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryCapability ctx,
  ) {
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
        ctx.onRelationCreate(
          sourceId,
          snappedTargetNodeId!,
          fromSide: sourcePort?.side,
          toSide: snappedTargetPort?.side,
        );
      }
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = ctx.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = ctx.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            ctx.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }

    ctx.setHoveredNode(hoveredNodeId);

    ctx.onNodeDragUpdate();
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      snappedTargetNodeId: snappedId,
      sourcePort: sourcePort,
      snappedTargetPort: snappedPort,
    );
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryCapability ctx,
  ) {
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }
    ctx.setHoveredNode(null);
    ctx.onNodeDragUpdate();
    return const CanvasIdle();
  }
}
