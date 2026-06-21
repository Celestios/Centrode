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
    String? snappedId;
    Port? snappedPort;
    String? hoveredNodeId;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      if (sourceNodeIds.contains(nodeId)) continue;

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      final port = vs.getClosestPortNew(pCanvas);
      if (port == null) continue;

      final dist = (pCanvas - port.edgePosition).distance;
      if (dist < AppConfig.interaction.snapDistance) {
        snappedId = nodeId;
        snappedPort = port;
        hoveredNodeId = nodeId;
        break;
      }

      if (hoveredNodeId == null && vs.rect.inflate(20.0).contains(pCanvas)) {
        hoveredNodeId = nodeId;
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
    String? snappedId;
    Port? snappedPort;
    String? hoveredNodeId;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      if (sourceNodeIds.contains(nodeId)) continue;
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      final port = vs.getClosestPortNew(pCanvas);
      if (port == null) continue;

      final dist = (pCanvas - port.edgePosition).distance;
      if (dist < AppConfig.interaction.snapDistance) {
        snappedId = nodeId;
        snappedPort = port;
        hoveredNodeId = nodeId;
        break;
      }

      if (hoveredNodeId == null && vs.rect.inflate(20.0).contains(pCanvas)) {
        hoveredNodeId = nodeId;
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
}
