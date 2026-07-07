part of '../base_interaction_state.dart';

class RelationDrawing extends CanvasInteractionState {
  final Set<String> sourceNodeIds;
  final Offset currentCursorPosition;
  final String? snappedTargetNodeId;
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
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

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
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

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
}
