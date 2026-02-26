// lib/features/graph/state/states/node_dragging.dart
part of '../canvas_interaction_states.dart';

/// Logger for NodeDragging state telemetry
final Logger _nodeDragLog = Logger('NodeDragging');

/// State when a node is being dragged.
///
/// Updates the node position during drag and commits on pointer up.
/// The [grabOffset] ensures the cursor maintains relative position to the node.
class NodeDragging extends CanvasInteractionState {
  final String nodeId;
  final Offset grabOffset;

  const NodeDragging(this.nodeId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) {
      // [NEW] Dangling pointer diagnostic
      _nodeDragLog.severe(
        'Dangling Pointer: Dragging $nodeId but ViewState is null. Resetting to Idle.',
      );
      return const CanvasIdle(); // Defensive check for dangling pointers
    }

    // Apply continuous L1 snapping to the node's origin using Dynamic LOD
    final rawPos = pCanvas - grabOffset;
    final effectiveGridSize = _calculateEffectiveGridSize(ctx.currentScale);
    vs.positionNotifier.value = _snapToGrid(rawPos, effectiveGridSize);

    ctx.onNodeDragUpdate();
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null) {
      // [NEW] Telemetry for volatile-to-domain commit
      _nodeDragLog.info(
        'Drag Commit: ID=$nodeId, Final Position=${vs.positionNotifier.value}',
      );
      ctx.onNodeMove(nodeId, vs.positionNotifier.value);
    }
    return const CanvasIdle();
  }
}
