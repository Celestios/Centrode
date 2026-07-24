// lib/features/graph/state/states/relation_tip_drag_state.dart
part of '../base_interaction_state.dart';

final Logger _relationTipLog = Logger('RelationTipDragging');

class RelationTipDragging extends CanvasInteractionState {
  final RawUuid relationId;
  final bool
  isStartTip; // true = dragging from/source tip, false = dragging to/target tip
  final Offset originalPosition;
  final Offset currentCursorPosition;

  /// The currently snapped target node ID, if any.
  final RawUuid? snappedTargetNodeId;

  /// The side of the target node to connect to, if any.
  final PortSide? snappedTargetSide;

  /// Whether the snap to the port is explicit (within 16px proximity).
  final bool isExplicit;

  /// The snapped port, if any.
  final Port? snappedPort;

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
    this.snappedPort,
  });

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    // Find the relation to determine the opposite node ID (to prevent self-loops)
    RawUuid? oppositeNodeId;
    for (final r in ctx.getRelations()) {
      if (r.id == relationId) {
        oppositeNodeId = isStartTip ? r.toNodeId : r.fromNodeId;
        break;
      }
    }

    final snap = findNearestSnap(
      pCanvas,
      ctx,
      oppositeNodeId != null ? {oppositeNodeId} : const {},
    );
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final snappedPortSide = snap.snappedPort?.side;
    final isExplicit = snap.snappedNodeId != null;

    ctx.onNodeDragUpdate(); // Pulse MovementNotifier to redraw the drag line
    _relationTipLog.fine('handlePointerMove relation=$relationId snap=${snappedId ?? "none"}');
    return RelationTipDragging(
      relationId: relationId,
      isStartTip: isStartTip,
      originalPosition: originalPosition,
      currentCursorPosition: pCanvas,
      snappedTargetNodeId: snappedId,
      snappedTargetSide: snappedPortSide,
      isExplicit: isExplicit,
      snappedPort: snappedPort,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryCapability ctx,
  ) {
    _relationTipLog.info('handlePointerUp relation=$relationId snapped=${snappedTargetNodeId ?? "none"} side=${snappedTargetSide ?? "none"}');
    if (snappedTargetNodeId != null) {
      if (isStartTip) {
        ctx.onRelationUpdateLayout(
          relationId,
          fromNodeId: snappedTargetNodeId,
          fromSide: isExplicit && snappedPort != null ? snappedPort!.side : null,
        );
      } else {
        ctx.onRelationUpdateLayout(
          relationId,
          toNodeId: snappedTargetNodeId,
          toSide: isExplicit && snappedPort != null ? snappedPort!.side : null,
        );
      }
    }

    ctx.onNodeDragUpdate(); // Repaint
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryCapability ctx,
  ) {
    ctx.onNodeDragUpdate(); // Repaint
    return const CanvasIdle();
  }
}
