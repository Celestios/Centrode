// lib/features/graph/state/states/canvas_idle.dart
part of '../base_interaction_state.dart';

/// Logger for CanvasIdle state telemetry
final Logger _canvasIdleLog = Logger('CanvasIdle');

/// The default idle state - no active interaction.
///
/// Performs hit-testing on pointer down to determine the next state:
/// - Port hit: transitions to [RelationDrawing]
/// - Node body hit: transitions to [NodeDragging]
/// - Double-tap: creates node (on canvas) or enters edit mode (on entity)
class CanvasIdle extends CanvasInteractionState {
  @override
  final MouseCursor cursor;

  const CanvasIdle({this.cursor = SystemMouseCursors.basic});

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    if (e.buttons == kSecondaryMouseButton) {
      _canvasIdleLog.fine('Right-click detected: Preserving idle for panning');
      return this;
    }

    final result = HitTestResolver().resolve(pCanvas, ctx, isDoubleTap);
    final activeEditId = ctx.getActiveEditId();
    final selectedEntities = ctx.getSelectedEntities();

    switch (result.type) {
      case HitTestType.relationTipStart:
      case HitTestType.relationTipEnd:
        return RelationTipDragging(
          relationId: result.relationId!,
          isStartTip: result.type == HitTestType.relationTipStart,
          originalPosition: result.originalPosition!,
          currentCursorPosition: pCanvas,
        );

      case HitTestType.metadataSphere:
        ctx.openDataInspector(result.hitNodeId!);
        return this;

      case HitTestType.expandToggle:
        ctx.toggleNodeExpansion(result.hitNodeId!);
        return this;

      case HitTestType.resizeRight:
      case HitTestType.resizeLeft:
        return _transitionToResizing(result, pCanvas, ctx);

      case HitTestType.body:
        if (activeEditId != null && result.hitNodeId != activeEditId) {
          ctx.onCommitActiveEdit();
        }
        if (!selectedEntities.contains(result.hitNodeId)) {
          ctx.onSelectEntity(result.hitNodeId);
        }
        return _transitionToDragging(result, pCanvas, ctx, selectedEntities);

      case HitTestType.rightClick:
      case HitTestType.relationLabel:
      case HitTestType.none:
        break;
    }

    final hitEntityId = result.hitEntityId ?? result.hitNodeId;
    final hitResize = result.type == HitTestType.resizeRight ||
        result.type == HitTestType.resizeLeft;

    if (activeEditId != null && (hitEntityId != activeEditId || hitResize)) {
      ctx.onCommitActiveEdit();
    }

    _canvasIdleLog.fine('Selection Intent: HitEntity=$hitEntityId');
    if (hitEntityId == null || !selectedEntities.contains(hitEntityId)) {
      ctx.onSelectEntity(hitEntityId);
    }

    if (hitEntityId != null && hitEntityId == activeEditId && !hitResize) {
      return this;
    }

    if (e.buttons == kPrimaryMouseButton &&
        hitEntityId == null &&
        !isDoubleTap) {
      return MarqueeSelecting(pCanvas, pCanvas);
    }

    if (isDoubleTap) {
      if (hitEntityId == null) {
        final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
        final snappedPos = _snapToGrid(pCanvas, effectiveGridSize);
        ctx.onCreateNode(snappedPos);
      } else {
        ctx.onEnterEditMode(hitEntityId);
      }
      return this;
    }

    return this;
  }

  CanvasInteractionState _transitionToResizing(
    PointerHitResult result,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final hitNodeId = result.hitNodeId!;
    final draggedEdge = result.draggedEdge!;
    final vs = ctx.nodeViewStates[hitNodeId]!;
    final initialLeft = vs.positionNotifier.value.dx;
    final initialWidth = vs.sizeNotifier.value.width;
    final double grabOffsetX;
    if (draggedEdge == ResizeEdge.right) {
      grabOffsetX = pCanvas.dx - (initialLeft + initialWidth);
    } else {
      grabOffsetX = pCanvas.dx - initialLeft;
    }

    final node = ctx.getNode(hitNodeId);
    final resizeFontSize =
        node?.resolvedStyle?.fontSize ?? AppConfig.node.defaultFontSize;
    return NodeResizing(
      hitNodeId,
      draggedEdge,
      grabOffsetX,
      initialLeft,
      initialWidth,
      resizeFontSize,
    );
  }

  CanvasInteractionState _transitionToDragging(
    PointerHitResult result,
    Offset pCanvas,
    InteractionContext ctx,
    Set<String> selectedEntities,
  ) {
    final hitNodeId = result.hitNodeId!;
    final nodeIdsInSelection = selectedEntities
        .where((id) => ctx.nodeViewStates.containsKey(id))
        .toList();
    if (nodeIdsInSelection.length > 1 &&
        nodeIdsInSelection.contains(hitNodeId)) {
      final originalPositions = {
        for (final id in nodeIdsInSelection)
          id: ctx.nodeViewStates[id]!.positionNotifier.value,
      };
      return GroupDragging(
        nodeIds: nodeIdsInSelection,
        anchorNodeId: hitNodeId,
        grabOffset:
            pCanvas - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value,
        originalPositions: originalPositions,
      );
    } else {
      return NodeDragging(
        hitNodeId,
        pCanvas - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value,
      );
    }
  }

  @override
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    // Use spatial grid to find candidate nodes near the cursor (O(K) not O(N))
    final candidateIds = ctx.spatialGrid.queryPoint(pCanvas);
    if (candidateIds.isEmpty) {
      ctx.setHoveredNodeMetadata(null);
      return cursor == SystemMouseCursors.basic
          ? this
          : const CanvasIdle(cursor: SystemMouseCursors.basic);
    }

    // Check candidates in reverse z-order for proper hit priority
    final zOrder = ctx.zOrder;
    for (int i = zOrder.length - 1; i >= 0; i--) {
      final nodeId = zOrder[i];
      if (!candidateIds.contains(nodeId)) continue;

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      if (vs.rightResizeHitbox.contains(pCanvas) ||
          vs.leftResizeHitbox.contains(pCanvas)) {
        ctx.setHoveredNodeMetadata(null);
        return cursor == SystemMouseCursors.resizeLeftRight
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.resizeLeftRight);
      }

      if (vs.lineCount > AppConfig.node.collapsedLineLimit && vs.expandToggleHitbox.contains(pCanvas)) {
        ctx.setHoveredNodeMetadata(null);
        return cursor == SystemMouseCursors.click
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.click);
      }

      if (HitTestResolver.isMetadataSphereHit(pCanvas, ctx, nodeId)) {
        ctx.setHoveredNodeMetadata(nodeId);
        return cursor == SystemMouseCursors.click
            ? this
            : const CanvasIdle(cursor: SystemMouseCursors.click);
      }
    }

    ctx.setHoveredNodeMetadata(null);
    return cursor == SystemMouseCursors.basic
        ? this
        : const CanvasIdle(cursor: SystemMouseCursors.basic);
  }
}
