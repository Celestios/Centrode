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
  Timer? _snapTimer;
  bool _hasMoved = false;

  NodeDragging(this.nodeId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryAndViewportCapability ctx,
  ) {
    _hasMoved = true;
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) {
      _snapTimer?.cancel();
      _nodeDragLog.severe(
        'Dangling Pointer: Dragging $nodeId but ViewState is null. Resetting to Idle.',
      );
      ctx.setNodeDragging(nodeId, false);
      return const CanvasIdle();
    }

    ctx.setNodeDragging(nodeId, true);
    final rawPos = pCanvas - grabOffset;
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
    final snappedPos = _snapToGrid(rawPos, effectiveGridSize);

    // Continuous visual movement
    vs.positionNotifier.value = rawPos;
    ctx.onNodesDrag([(nodeId, snappedPos)]);

    // Delayed grid snap when mouse pauses
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 150), () {
      vs.positionNotifier.value = snappedPos;
    });

    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    _snapTimer?.cancel();
    final vs = ctx.nodeViewStates[nodeId];
    ctx.setNodeDragging(nodeId, false);
    if (vs != null && _hasMoved) {
      final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
      final snappedPos = _snapToGrid(vs.positionNotifier.value, effectiveGridSize);
      vs.positionNotifier.value = snappedPos;
      _nodeDragLog.info(
        'Drag Commit: ID=$nodeId, Final Position=$snappedPos',
      );
      ctx.onNodeMove(nodeId, snappedPos);
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    _snapTimer?.cancel();
    ctx.setNodeDragging(nodeId, false);
    return const CanvasIdle();
  }
}
