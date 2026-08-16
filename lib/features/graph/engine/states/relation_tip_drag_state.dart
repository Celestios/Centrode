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

  final Timer? hoverHoldTimer;
  final RawUuid? hoveredContainerId;

  @override
  MouseCursor get cursor => SystemMouseCursors.grab;

  @override
  bool get allowsAutoPan => true;

  const RelationTipDragging({
    required this.relationId,
    required this.isStartTip,
    required this.originalPosition,
    required this.currentCursorPosition,
    this.snappedTargetNodeId,
    this.snappedTargetSide,
    this.isExplicit = false,
    this.snappedPort,
    this.hoverHoldTimer,
    this.hoveredContainerId,
  });

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryCapability;
    // Find the relation to determine the opposite node ID (to prevent self-loops)
    RawUuid? oppositeNodeId;
    for (final r in c.getRelations()) {
      if (r.id == relationId) {
        oppositeNodeId = isStartTip ? r.toNodeId : r.fromNodeId;
        break;
      }
    }

    final snap = findNearestSnap(
      pCanvas,
      c,
      oppositeNodeId != null ? {oppositeNodeId} : const {},
    );
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final snappedPortSide = snap.snappedPort?.side;
    final isExplicit = snap.snappedNodeId != null;

    final prevSnappedId = snappedTargetNodeId;
    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != this.snappedPort) {
        final targetVs = c.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = c.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          c.onRelationSnapPreview(
            relationId: relationId,
            isStartTip: isStartTip,
            targetNodeId: snappedId,
            targetNodeTable: targetNode?.tableName ?? 'Nodes',
            targetSide: snappedPortSide,
            overridePosition: overridePos,
          );
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      c.onRelationSnapPreviewClear(relationId);
    }

    Timer? nextHoverHoldTimer = hoverHoldTimer;
    RawUuid? nextHoveredContainerId = hoveredContainerId;

    final activeScope = c.activeScope;
    if (activeScope is RootViewportScope) {
      ContainerUiNode? hoveredContainer;
      for (final candidateId in c.nodeViewStates.keys) {
        final candNode = c.getNode(candidateId);
        if (candNode is! ContainerUiNode) continue;
        if (candNode.parentContainerId != null) continue;
        final candVs = c.nodeViewStates[candidateId];
        if (candVs != null && candVs.rect.contains(pCanvas)) {
          hoveredContainer = candNode;
          break;
        }
      }

      if (hoveredContainer != null) {
        if (hoveredContainer.id != hoveredContainerId) {
          nextHoveredContainerId = hoveredContainer.id;
          nextHoverHoldTimer?.cancel();
          final targetContainer = hoveredContainer;
          nextHoverHoldTimer = Timer(const Duration(milliseconds: 750), () {
            c.openContainer(targetContainer, animate: true);
          });
        }
      } else {
        nextHoverHoldTimer?.cancel();
        nextHoverHoldTimer = null;
        nextHoveredContainerId = null;
      }
    }

    c.onNodeDragUpdate(); // Pulse MovementNotifier to redraw the drag line
    c.setHoveredNode(snap.hoveredNodeId);
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
      hoverHoldTimer: nextHoverHoldTimer,
      hoveredContainerId: nextHoveredContainerId,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    hoverHoldTimer?.cancel();
    final c = ctx as GeometryCapability;
    _relationTipLog.info('handlePointerUp relation=$relationId snapped=${snappedTargetNodeId ?? "none"} side=${snappedTargetSide ?? "none"}');
    c.onRelationSnapPreviewClear(relationId);
    if (snappedTargetNodeId != null) {
      if (isStartTip) {
        c.onRelationUpdateLayout(
          relationId,
          fromNodeId: snappedTargetNodeId,
          fromSide: isExplicit && snappedPort != null ? snappedPort!.side : null,
        );
      } else {
        c.onRelationUpdateLayout(
          relationId,
          toNodeId: snappedTargetNodeId,
          toSide: isExplicit && snappedPort != null ? snappedPort!.side : null,
        );
      }
    }

    c.onNodeDragUpdate(); // Repaint
    c.setHoveredNode(null);
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) {
    hoverHoldTimer?.cancel();
    final c = ctx as GeometryCapability;
    c.onRelationSnapPreviewClear(relationId);
    c.onNodeDragUpdate(); // Repaint
    c.setHoveredNode(null);
    return const CanvasIdle();
  }
}
