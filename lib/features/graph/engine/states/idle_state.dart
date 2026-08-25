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
    final mode = CanvasToolMode.fromString(ctx.toolMode);
    if (e.buttons == kSecondaryMouseButton || mode.isPan) {
      _canvasIdleLog.fine('Pan mode or Right-click detected: Preserving idle for panning');
      return this;
    }

    final result = HitTestResolver().resolve(pCanvas, ctx, isDoubleTap);
    final activeEditId = ctx.getActiveEditId();
    final selectedEntities = ctx.getSelectedEntities();

    switch (result.type) {
      case HitTestType.optAreaClose:
        ctx.onSetOptArea(null);
        return this;

      case HitTestType.optAreaResizeLeft:
        return OptAreaResizing(
          edge: OptAreaResizeEdge.left,
          initialRect: ctx.optArea!,
          startPos: pCanvas,
        );

      case HitTestType.optAreaResizeRight:
        return OptAreaResizing(
          edge: OptAreaResizeEdge.right,
          initialRect: ctx.optArea!,
          startPos: pCanvas,
        );

      case HitTestType.optAreaResizeTop:
        return OptAreaResizing(
          edge: OptAreaResizeEdge.top,
          initialRect: ctx.optArea!,
          startPos: pCanvas,
        );

      case HitTestType.optAreaResizeBottom:
        return OptAreaResizing(
          edge: OptAreaResizeEdge.bottom,
          initialRect: ctx.optArea!,
          startPos: pCanvas,
        );

      case HitTestType.relationTipStart:
      case HitTestType.relationTipEnd:
        ctx.setHoveredPort(null);
        return RelationTipDragging(
          relationId: result.relationId!,
          isStartTip: result.type == HitTestType.relationTipStart,
          originalPosition: result.originalPosition!,
          currentCursorPosition: pCanvas,
        );

      case HitTestType.port:
        ctx.setHoveredPort(null);
        return RelationDrawing(
          {result.hitNodeId!},
          pCanvas,
          sourcePort: result.hitPort,
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
        if (isDoubleTap) {
          ctx.onEnterEditMode(result.hitNodeId!);
          return this;
        }
        if (activeEditId == result.hitNodeId) {
          return this;
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

    if (e.buttons == kPrimaryMouseButton && hitEntityId == null) {
      if (mode.isOptimize) {
        ctx.onSetOptArea(null);
        return OptAreaDrawing(pCanvas, pCanvas);
      }
      if (mode.isFrame) {
        return FrameDrawing(pCanvas, pCanvas);
      }
      return MarqueeSelecting(pCanvas, pCanvas);
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
    Set<RawUuid> selectedEntities,
  ) {
    final hitNodeId = result.hitNodeId!;
    final hitNode = ctx.getNode(hitNodeId);

    final Set<RawUuid> nodesToDrag = {};
    if (selectedEntities.contains(hitNodeId)) {
      nodesToDrag.addAll(
        selectedEntities.where((id) => ctx.nodeViewStates.containsKey(id)),
      );
    } else {
      nodesToDrag.add(hitNodeId);
    }

    // If dragging a node belonging to a group, include all group members
    if (hitNode?.groupId != null) {
      for (final entry in ctx.nodeViewStates.entries) {
        final otherNode = ctx.getNode(entry.key);
        if (otherNode != null && otherNode.groupId == hitNode!.groupId) {
          nodesToDrag.add(entry.key);
        }
      }
    }

    // If dragging a FrameUiNode, include all nodes whose center is inside the frame bounds
    if (hitNode is FrameUiNode) {
      final frameVs = ctx.nodeViewStates[hitNodeId];
      if (frameVs != null) {
        final frameRect = frameVs.rect;
        for (final entry in ctx.nodeViewStates.entries) {
          final otherId = entry.key;
          if (otherId == hitNodeId) continue;
          final otherNode = ctx.getNode(otherId);
          if (otherNode == null || otherNode.parentContainerId != hitNode.parentContainerId) continue;

          final otherVs = entry.value;
          final otherCenter = otherVs.positionNotifier.value +
              Offset(
                (otherVs.sizeNotifier.value.width > 0 ? otherVs.sizeNotifier.value.width : otherNode.size.width) / 2,
                (otherVs.sizeNotifier.value.height > 0 ? otherVs.sizeNotifier.value.height : otherNode.size.height) / 2,
              );
          if (frameRect.contains(otherCenter)) {
            nodesToDrag.add(otherId);
          }
        }
      }
    }

    if (nodesToDrag.length > 1) {
      final originalPositions = {
        for (final id in nodesToDrag)
          if (ctx.nodeViewStates.containsKey(id))
            id: ctx.nodeViewStates[id]!.positionNotifier.value,
      };
      return GroupDragging(
        nodeIds: nodesToDrag,
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
    // Check OptArea hits first (close button and 4-side resize handles)
    final optHit = const HitTestResolver().resolveOptAreaHit(pCanvas, ctx);
    if (optHit != null) {
      ctx.setHoveredNode(null);
      ctx.setHoveredNodeMetadata(null);
      ctx.setHoveredPort(null);
      final targetCursor = optHit.type == HitTestType.optAreaClose
          ? SystemMouseCursors.click
          : (optHit.type == HitTestType.optAreaResizeLeft ||
                  optHit.type == HitTestType.optAreaResizeRight)
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown;

      return cursor == targetCursor
          ? this
          : CanvasIdle(cursor: targetCursor);
    }

    final activeScope = ctx.activeScope;
    Set<RawUuid> candidateIds;
    if (activeScope is ContainerViewportScope) {
      final containerGrid = ctx.spatialIndex.getContainerGrid(activeScope.containerId);
      candidateIds = containerGrid?.queryPoint(pCanvas) ?? {};
    } else {
      candidateIds = ctx.spatialGrid.queryPoint(pCanvas);
    }

    if (candidateIds.isEmpty) {
      candidateIds = ctx.nodeViewStates.keys.toSet();
    }

    // Check candidates in reverse z-order, prioritizing non-frame nodes over enclosing frames
    final zOrder = ctx.zOrder;
    final orderedCandidateIds = [
      for (int i = zOrder.length - 1; i >= 0; i--)
        if (candidateIds.contains(zOrder[i]) && ctx.getNode(zOrder[i]) is! FrameUiNode)
          zOrder[i],
      for (int i = zOrder.length - 1; i >= 0; i--)
        if (candidateIds.contains(zOrder[i]) && ctx.getNode(zOrder[i]) is FrameUiNode)
          zOrder[i],
    ];

    for (final nodeId in orderedCandidateIds) {
      final node = ctx.getNode(nodeId);
      if (node == null) continue;

      if (activeScope is ContainerViewportScope) {
        if (node.parentContainerId != activeScope.containerId) continue;
      } else {
        if (node.parentContainerId != null) continue;
      }

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      if (node is! DrawingUiNode &&
          (vs.rightResizeHitbox.contains(pCanvas) ||
           vs.leftResizeHitbox.contains(pCanvas))) {
        ctx.setHoveredNode(null);
        ctx.setHoveredNodeMetadata(null);
        ctx.setHoveredPort(null);
        return cursor == SystemMouseCursors.resizeLeftRight
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.resizeLeftRight);
      }
      if (vs.lineCount > AppConfig.node.collapsedLineLimit && vs.getExpandToggleHitbox(node).contains(pCanvas)) {
        ctx.setHoveredNode(null);
        ctx.setHoveredNodeMetadata(null);
        ctx.setHoveredPort(null);
        return cursor == SystemMouseCursors.click
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.click);
      }

      // Show metadata preview when hovering over metadata sphere
      if (HitTestResolver.isMetadataSphereHit(pCanvas, ctx, nodeId)) {
        ctx.setHoveredNode(nodeId);
        ctx.setHoveredNodeMetadata(nodeId);
        return cursor == SystemMouseCursors.click
            ? this
            : const CanvasIdle(cursor: SystemMouseCursors.click);
      }

      // Show ports when hovering anywhere on the node (including port offset zone)
      if (vs.rect.inflate(12.0 * vs.currentScale).contains(pCanvas)) {
        if (node is ContainerUiNode) {
          final screenWidth = (vs.sizeNotifier.value.width > 0 ? vs.sizeNotifier.value.width : node.size.width) * vs.currentScale;
          if (!node.isClosed || screenWidth >= 180.0) {
            continue;
          }
        }
        ctx.setHoveredNode(nodeId);
        ctx.setHoveredNodeMetadata(null);

        Port? hoveredPort;
        for (final port in vs.ports.allPorts) {
          if ((pCanvas - port.position).distance < AppConfig.port.hitRadius * vs.currentScale) {
            hoveredPort = port;
            break;
          }
        }
        ctx.setHoveredPort(hoveredPort);

        return cursor == SystemMouseCursors.click
            ? this
            : const CanvasIdle(cursor: SystemMouseCursors.click);
      }
    }

    ctx.setHoveredNode(null);
    ctx.setHoveredNodeMetadata(null);
    ctx.setHoveredPort(null);
    return cursor == SystemMouseCursors.basic
        ? this
        : const CanvasIdle(cursor: SystemMouseCursors.basic);
  }
}
