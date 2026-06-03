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
  final double initialLeft;
  final double initialWidth;

  @override
  MouseCursor get cursor => SystemMouseCursors.resizeLeftRight;

  const NodeResizing(
    this.nodeId,
    this.edge,
    this.grabOffsetX,
    this.initialLeft,
    this.initialWidth,
  );

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle();

    // Snap to the same dynamic LOD grid used by NodeDragging
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);

    switch (edge) {
      // TODO: the code below can be extracted to helper functions to follow DRY.
      case ResizeEdge.right:
        // Proposed right edge (raw, unsnapped)
        final rawRight = pCanvas.dx - grabOffsetX;
        // Snap the right‑edge position using an Offset wrapper
        final snappedRight = _snapToGrid(
          Offset(rawRight, 0),
          effectiveGridSize,
        ).dx;
        // New width = snapped right edge minus initial left
        double newWidth = snappedRight - initialLeft;
        if (newWidth < AppConfig.node.minWidth) {
          newWidth = AppConfig.node.minWidth;
        } else if (newWidth > AppConfig.node.maxWidth) {
          newWidth = AppConfig.node.maxWidth;
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
        // Right edge stays fixed: initialLeft + initialWidth
        final fixedRight = initialLeft + initialWidth;
        double newWidth = fixedRight - snappedLeft;
        if (newWidth < AppConfig.node.minWidth) {
          newWidth = AppConfig.node.minWidth;
          // Adjust left edge so the right edge doesn’t move
          vs.positionNotifier.value = Offset(
            fixedRight - newWidth,
            vs.positionNotifier.value.dy,
          );
        } else {
          if (newWidth > AppConfig.node.maxWidth) {
            newWidth = AppConfig.node.maxWidth;
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
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null && vs.dragWidthNotifier.value != null) {
      final newWidth = vs.dragWidthNotifier.value!;
      final leftEdge = vs.positionNotifier.value.dx;
      final rightEdge = leftEdge + newWidth;
      ctx.updateNodeWidth(nodeId, leftEdge, rightEdge);
      // Do NOT clear dragWidthNotifier – let rehydrate() handle it
    }
    return const CanvasIdle();
  }
}
