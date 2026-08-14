// lib/features/graph/state/states/group_dragging.dart
part of '../base_interaction_state.dart';

/// Logger for GroupDragging state telemetry
final Logger _groupDragLog = Logger('GroupDragging');

/// State when a group of nodes is being dragged.
///
/// Updates positions of all selected nodes during drag relative to the anchor node,
/// and commits their positions on pointer up.
class GroupDragging extends CanvasInteractionState {
  final List<RawUuid> nodeIds;
  final RawUuid anchorNodeId;
  final Offset grabOffset;
  final Map<RawUuid, Offset> originalPositions;
  Timer? _snapTimer;
  bool _hasMoved = false;

  GroupDragging({
    required Iterable<RawUuid> nodeIds,
    required this.anchorNodeId,
    required this.grabOffset,
    required this.originalPositions,
  }) : nodeIds = nodeIds.toList();

  @override
  bool get allowsAutoPan => true;

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryAndViewportCapability ctx,
  ) {
    _hasMoved = true;
    final anchorVs = ctx.nodeViewStates[anchorNodeId];
    if (anchorVs == null) {
      _snapTimer?.cancel();
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

    final rawAnchorPos = pCanvas - grabOffset;
    final originalAnchorPos = originalPositions[anchorNodeId];
    if (originalAnchorPos == null) {
      _snapTimer?.cancel();
      _groupDragLog.severe(
        'Anchor node $anchorNodeId missing original position.',
      );
      return const CanvasIdle();
    }

    final rawDelta = rawAnchorPos - originalAnchorPos;
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
    final snappedAnchorPos = _snapToGrid(rawAnchorPos, effectiveGridSize);
    final snappedDelta = snappedAnchorPos - originalAnchorPos;

    final List<(RawUuid, Offset)> dragUpdates = [];

    // Continuous visual movement
    for (final id in nodeIds) {
      final vs = ctx.nodeViewStates[id];
      final originalPos = originalPositions[id];
      if (vs != null && originalPos != null) {
        vs.positionNotifier.value = originalPos + rawDelta;
        dragUpdates.add((id, originalPos + snappedDelta));
      }
    }

    ctx.onNodesDrag(dragUpdates);

    // Delayed snap when mouse pauses
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 150), () {
      for (final id in nodeIds) {
        final vs = ctx.nodeViewStates[id];
        final originalPos = originalPositions[id];
        if (vs != null && originalPos != null) {
          vs.positionNotifier.value = _snapToGrid(
            originalPos + snappedDelta,
            effectiveGridSize,
          );
        }
      }
    });

    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    _snapTimer?.cancel();
    _groupDragLog.info('Group Drag Commit for ${nodeIds.length} nodes');
    final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
    for (final id in nodeIds) {
      ctx.setNodeDragging(id, false);
      final vs = ctx.nodeViewStates[id];
      if (vs != null && _hasMoved) {
        final snappedPos = _snapToGrid(vs.positionNotifier.value, effectiveGridSize);
        vs.positionNotifier.value = snappedPos;
        ctx.onNodeMove(id, snappedPos);
        final node = ctx.getNode(id);
        if (node != null) {
          vs.positionNotifier.value = node.position;
        }
      }
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryAndViewportCapability ctx,
  ) {
    _snapTimer?.cancel();
    for (final id in nodeIds) {
      ctx.setNodeDragging(id, false);
    }
    return const CanvasIdle();
  }
}
