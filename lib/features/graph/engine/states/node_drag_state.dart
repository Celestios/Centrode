// lib/features/graph/state/states/node_dragging.dart
part of '../base_interaction_state.dart';

/// Logger for NodeDragging state telemetry
final Logger _nodeDragLog = Logger('NodeDragging');

/// State when a node is being dragged.
///
/// Updates the node position during drag and commits on pointer up.
/// The [grabOffset] ensures the cursor maintains relative position to the node.
class NodeDragging extends CanvasInteractionState {
  final RawUuid nodeId;
  final Offset grabOffset;

  const NodeDragging(this.nodeId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) {
      // [NEW] Dangling pointer diagnostic
      _nodeDragLog.severe(
        'Dangling Pointer: Dragging $nodeId but ViewState is null. Resetting to Idle.',
      );
      ctx.setNodeDragging(nodeId, false);
      return const CanvasIdle(); // Defensive check for dangling pointers
    }

    ctx.setNodeDragging(nodeId, true);
    final rawPos = pCanvas - grabOffset;
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
    final snappedPos = _snapToGrid(rawPos, effectiveGridSize);
    vs.positionNotifier.value = snappedPos;

    ctx.onNodesDrag([(nodeId, snappedPos)]);
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    ctx.setNodeDragging(nodeId, false);
    if (vs != null) {
      // [NEW] Telemetry for volatile-to-domain commit
      _nodeDragLog.info(
        'Drag Commit: ID=$nodeId, Final Position=${vs.positionNotifier.value}',
      );
      ctx.onNodeMove(nodeId, vs.positionNotifier.value);
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    ctx.setNodeDragging(nodeId, false);
    return const CanvasIdle();
  }
}
