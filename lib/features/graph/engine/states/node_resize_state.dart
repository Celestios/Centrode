// lib/features/graph/state/states/node_resizing.dart
part of '../base_interaction_state.dart';

final Logger _nodeResizeLog = Logger('NodeResizing');

/// Which edge of the node is being dragged for resizing.
enum ResizeEdge { left, right }

/// State when dragging an edge of a node to resize its width.
/// Applies continuous grid snapping (like [NodeDragging]) and supports both
/// left and right edges. All changes are volatile until [handlePointerUp].
class NodeResizing extends CanvasInteractionState {
  final RawUuid nodeId;
  final ResizeEdge edge;
  final double grabOffsetX;
  final double initialLeft;
  final double initialWidth;
  final double fontSize;

  @override
  MouseCursor get cursor => SystemMouseCursors.resizeLeftRight;

  const NodeResizing(
    this.nodeId,
    this.edge,
    this.grabOffsetX,
    this.initialLeft,
    this.initialWidth,
    this.fontSize,
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

    final bool movesLeft = edge == ResizeEdge.left;
    final rawMovePos = pCanvas.dx - grabOffsetX;
    final snappedPos = _snapToGrid(Offset(rawMovePos, 0), effectiveGridSize).dx;
    final fixedEdge = movesLeft ? initialLeft + initialWidth : initialLeft;
    final rawWidth = movesLeft ? fixedEdge - snappedPos : snappedPos - initialLeft;
    final minW = AppConfig.node.scaledMinWidth(fontSize);
    final maxW = AppConfig.node.scaledMaxWidth(fontSize);
    final clampedWidth = rawWidth.clamp(minW, maxW);
    final newLeft = movesLeft ? fixedEdge - clampedWidth : initialLeft;
    vs.positionNotifier.value = Offset(newLeft, vs.positionNotifier.value.dy);
    vs.dragWidthNotifier.value = clampedWidth;

    _nodeResizeLog.fine('handlePointerMove nodeId=$nodeId edge=$edge width=$clampedWidth');

    final node = ctx.getNode(nodeId);
    if (node != null) {
      final result = const DefaultNodeLayoutStrategy().calculateSize(node, overrideWidth: clampedWidth);
      vs.sizeNotifier.value = result.size;
      vs.lineCountNotifier.value = result.lineCount;
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
      _nodeResizeLog.info('handlePointerUp nodeId=$nodeId committed width=${vs.dragWidthNotifier.value}');
      final newWidth = vs.dragWidthNotifier.value!;
      final leftEdge = vs.positionNotifier.value.dx;
      final rightEdge = leftEdge + newWidth;
      ctx.updateNodeWidth(nodeId, leftEdge, rightEdge);
      // Do NOT clear dragWidthNotifier – let rehydrate() handle it
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null) {
      final node = ctx.getNode(nodeId);
      if (node != null) {
        vs.rehydrate(node);
        ctx.onNodeDragUpdate();
      }
    }
    return const CanvasIdle();
  }
}
