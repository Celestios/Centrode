// lib/features/graph/state/states/relation_tip_drag_state.dart
part of '../base_interaction_state.dart';

class RelationTipDragging extends CanvasInteractionState {
  final String relationId;
  final bool isStartTip; // true = dragging from/source tip, false = dragging to/target tip
  final Offset originalPosition;
  final Offset currentCursorPosition;

  /// The currently snapped target node ID, if any.
  final String? snappedTargetNodeId;

  /// The side of the target node to connect to, if any.
  final String? snappedTargetSide;

  /// Whether the snap to the port is explicit (within 16px proximity).
  final bool isExplicit;

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  const RelationTipDragging({
    required this.relationId,
    required this.isStartTip,
    required this.originalPosition,
    required this.currentCursorPosition,
    this.snappedTargetNodeId,
    this.snappedTargetSide,
    this.isExplicit = false,
  });

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    // 1. Snapping logic to find nearby target node & its closest port (same as RelationDrawing)
    String? snappedId;
    String? snappedPort;
    bool isExplicit = false;

    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    // Find the relation to determine the opposite node ID (to prevent self-loops)
    String? oppositeNodeId;
    for (final r in ctx.getRelations()) {
      if (r.id == relationId) {
        oppositeNodeId = isStartTip ? r.toNodeId : r.fromNodeId;
        break;
      }
    }

    double bestTargetDist = double.infinity;

    for (final nodeId in nodeIds) {
      if (nodeId == oppositeNodeId) continue; // Prevent self-loops

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      // Check distance to target's closest port
      final closest = vs.getClosestPort(pCanvas);
      final dist = (pCanvas - closest.position).distance;
      if (dist < AppConfig.interaction.snapDistance && dist < bestTargetDist) {
        bestTargetDist = dist;
        snappedId = nodeId;
        snappedPort = closest.name;
        isExplicit = dist < 16.0;
      }
    }

    ctx.onNodeDragUpdate(); // Pulse MovementNotifier to redraw the drag line
    return RelationTipDragging(
      relationId: relationId,
      isStartTip: isStartTip,
      originalPosition: originalPosition,
      currentCursorPosition: pCanvas,
      snappedTargetNodeId: snappedId,
      snappedTargetSide: snappedPort,
      isExplicit: isExplicit,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    if (snappedTargetNodeId != null) {
      if (isStartTip) {
        ctx.onRelationUpdateLayout(
          relationId,
          fromNodeId: snappedTargetNodeId,
          fromSide: isExplicit ? snappedTargetSide : 'Auto',
        );
      } else {
        ctx.onRelationUpdateLayout(
          relationId,
          toNodeId: snappedTargetNodeId,
          toSide: isExplicit ? snappedTargetSide : 'Auto',
        );
      }
    }
    
    ctx.onNodeDragUpdate(); // Repaint
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) {
    ctx.onNodeDragUpdate(); // Repaint
    return const CanvasIdle();
  }
}
