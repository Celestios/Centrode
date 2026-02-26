// lib/features/graph/state/states/node_resizing.dart
part of '../canvas_interaction_states.dart';

/// [NEW] State when dragging the right edge of a node to resize its width.
/// Operates exclusively in visual memory until PointerUp, where it commits the DB patch.
class NodeResizing extends CanvasInteractionState {
  final String nodeId;
  final double grabOffsetX;

  /// The mouse cursor for resize interactions.
  @override
  MouseCursor get cursor => SystemMouseCursors.resizeLeftRight;

  const NodeResizing(this.nodeId, this.grabOffsetX);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle();

    // Calculate new width: Current pointer X minus the Node's original Left X
    double newWidth = pCanvas.dx - vs.positionNotifier.value.dx;
    if (newWidth < AppConfig.graph.node.minWidth) {
      newWidth = AppConfig.graph.node.minWidth;
    } // Minimum width safety constraint

    vs.dragWidthNotifier.value = newWidth;

    // Trigger repaint for the relation layer
    ctx.onNodeDragUpdate();
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null && vs.dragWidthNotifier.value != null) {
      ctx.onNodeResizeEnd(nodeId, vs.dragWidthNotifier.value!);

      // THE FIX: Do NOT clear the volatile state yet.
      // Leave it as the Optimistic UI cache. The ViewState's `rehydrate()`
      // method will automatically clear it once the DB successfully saves
      // and streams the new canonical aesthetics back to the widget.
      // vs.dragWidthNotifier.value = null;
    }
    return const CanvasIdle();
  }
}
