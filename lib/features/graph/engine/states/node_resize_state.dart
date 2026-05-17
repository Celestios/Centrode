// lib/features/graph/state/states/node_resizing.dart
part of '../base_interaction_state.dart';

/// Which edge of the node is being dragged for resizing.
enum ResizeEdge { left, right }

/// State when dragging an edge of a node to resize its width.
/// Applies continuous grid snapping (like [NodeDragging]) and supports both
/// left and right edges. All changes are volatile until [handlePointerUp].
class NodeResizing extends CanvasInteractionState {
  final String nodeId;
  final ResizeEdge edge;
  final double grabOffsetX;

  @override
  MouseCursor get cursor => SystemMouseCursors.resizeLeftRight;

  const NodeResizing(this.nodeId, this.edge, this.grabOffsetX);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle();

    // Snap to the same dynamic LOD grid used by NodeDragging
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);

    final double currentLeft = vs.positionNotifier.value.dx;
    final double currentWidth =
        vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width;

    switch (edge) {
      case ResizeEdge.right:
        // Proposed right edge (raw, unsnapped)
        final rawRight = pCanvas.dx - grabOffsetX;
        // Snap the right‑edge position using an Offset wrapper
        // TODO: note, had to wrapp in offset
        final snappedRight = _snapToGrid(
          Offset(rawRight, 0),
          effectiveGridSize,
        ).dx;
        // New width = snapped right edge minus current left
        double newWidth = snappedRight - currentLeft;
        if (newWidth < AppConfig.node.minWidth) {
          newWidth = AppConfig.node.minWidth;
        }
        vs.dragWidthNotifier.value = newWidth;
        break;

      case ResizeEdge.left:
        // Proposed left edge (raw)
        final rawLeft = pCanvas.dx - grabOffsetX;
        final snappedLeft = _snapToGrid(
          Offset(rawLeft, 0),
          effectiveGridSize,
        ).dx;
        // Right edge stays fixed: currentLeft + currentWidth
        final fixedRight = currentLeft + currentWidth;
        double newWidth = fixedRight - snappedLeft;
        if (newWidth < AppConfig.node.minWidth) {
          newWidth = AppConfig.node.minWidth;
          // Adjust left edge so the right edge doesn’t move
          vs.positionNotifier.value = Offset(
            fixedRight - newWidth,
            vs.positionNotifier.value.dy,
          );
        } else {
          vs.positionNotifier.value = Offset(
            snappedLeft,
            vs.positionNotifier.value.dy,
          );
        }
        vs.dragWidthNotifier.value = newWidth;
        break;
    }

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
      final newWidth = vs.dragWidthNotifier.value!;
      final leftEdge = vs.positionNotifier.value.dx;
      final rightEdge = leftEdge + newWidth;
      ctx.updateNodeWidth(leftEdge, rightEdge);
      // Do NOT clear dragWidthNotifier – let rehydrate() handle it
    }
    return const CanvasIdle();
  }
}
