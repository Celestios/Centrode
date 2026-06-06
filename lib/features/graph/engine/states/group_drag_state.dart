// lib/features/graph/state/states/group_dragging.dart
part of '../base_interaction_state.dart';

/// Logger for GroupDragging state telemetry
final Logger _groupDragLog = Logger('GroupDragging');

/// State when a group of nodes is being dragged.
///
/// Updates positions of all selected nodes during drag relative to the anchor node,
/// and commits their positions on pointer up.
class GroupDragging extends CanvasInteractionState {
  final List<String> nodeIds;
  final String anchorNodeId;
  final Offset grabOffset;
  final Map<String, Offset> originalPositions;

  const GroupDragging({
    required this.nodeIds,
    required this.anchorNodeId,
    required this.grabOffset,
    required this.originalPositions,
  });

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryAndViewportCapability ctx,
  ) {
    final anchorVs = ctx.nodeViewStates[anchorNodeId];
    if (anchorVs == null) {
      // Dangling pointer reset
      _groupDragLog.severe(
        'Dangling Pointer: Dragging group anchor $anchorNodeId but ViewState is null. Resetting to Idle.',
      );
      for (final id in nodeIds) {
        ctx.setNodeDragging(id, false);
      }
      return const CanvasIdle();
    }

    for (final id in nodeIds) {
      ctx.setNodeDragging(id, true);
    }

    // Snapped position of the anchor node
    final rawAnchorPos = pCanvas - grabOffset;
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
    final snappedAnchorPos = _snapToGrid(rawAnchorPos, effectiveGridSize);

    final originalAnchorPos = originalPositions[anchorNodeId];
    if (originalAnchorPos == null) {
      _groupDragLog.severe(
        'Anchor node $anchorNodeId missing original position.',
      );
      return const CanvasIdle();
    }

    final delta = snappedAnchorPos - originalAnchorPos;

    for (final id in nodeIds) {
      final vs = ctx.nodeViewStates[id];
      final originalPos = originalPositions[id];
      if (vs != null && originalPos != null) {
        vs.positionNotifier.value = _snapToGrid(
          originalPos + delta,
          effectiveGridSize,
        );
      }
    }

    ctx.onNodeDragUpdate();
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    _groupDragLog.info('Group Drag Commit for ${nodeIds.length} nodes');
    for (final id in nodeIds) {
      ctx.setNodeDragging(id, false);
      final vs = ctx.nodeViewStates[id];
      if (vs != null) {
        ctx.onNodeMove(id, vs.positionNotifier.value);
      }
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    for (final id in nodeIds) {
      ctx.setNodeDragging(id, false);
    }
    return const CanvasIdle();
  }
}
