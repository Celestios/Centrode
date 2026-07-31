part of '../base_interaction_state.dart';

class RelationDrawing extends CanvasInteractionState {
  final Set<RawUuid> sourceNodeIds;
  final Offset currentCursorPosition;
  final Offset initialCursorPosition;
  final RawUuid? snappedTargetNodeId;
  final Port? sourcePort;
  final Port? snappedTargetPort;

  const RelationDrawing(
    this.sourceNodeIds,
    this.currentCursorPosition, {
    Offset? initialCursorPosition,
    this.snappedTargetNodeId,
    this.sourcePort,
    this.snappedTargetPort,
  }) : initialCursorPosition = initialCursorPosition ?? currentCursorPosition;

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
    bool isDoubleTap,
  ) {
    return this;
  }

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = ctx.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = ctx.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            ctx.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }

    ctx.setHoveredNode(hoveredNodeId);
    ctx.onNodeDragUpdate();
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      initialCursorPosition: initialCursorPosition,
      snappedTargetNodeId: snappedId,
      sourcePort: sourcePort,
      snappedTargetPort: snappedPort,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryCapability ctx,
  ) {
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
        ctx.onRelationCreate(
          sourceId,
          snappedTargetNodeId!,
          fromSide: sourcePort?.side,
          toSide: snappedTargetPort?.side,
        );
      }
    } else if (sourceNodeIds.isNotEmpty) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);

        final sourceVs = ctx.nodeViewStates[sourceId];
        final sourceNode = ctx.getNode(sourceId);
        final sourcePos = sourceNode?.position ??
            (sourceVs != null ? sourceVs.positionNotifier.value : Offset.zero);
        final sourceSize =
            sourceVs?.sizeNotifier.value ?? const Size(160, 80);

        final isTap =
            (currentCursorPosition - initialCursorPosition).distance < 8.0;
        final Offset targetPos;

        if (isTap && sourcePort != null) {
          const spacing = 160.0;
          switch (sourcePort!.side) {
            case PortSide.right:
              targetPos = sourcePos + Offset(sourceSize.width + spacing, 0);
              break;
            case PortSide.left:
              targetPos = sourcePos - Offset(160.0 + spacing, 0);
              break;
            case PortSide.bottom:
              targetPos = sourcePos + Offset(0, sourceSize.height + spacing);
              break;
            case PortSide.top:
              targetPos = sourcePos - Offset(0, 80.0 + spacing);
              break;
            case PortSide.auto:
            default:
              targetPos = sourcePos + Offset(sourceSize.width + spacing, 0);
              break;
          }
        } else {
          targetPos = currentCursorPosition;
        }

        final double scale =
            ctx is ViewportCapability ? (ctx as ViewportCapability).currentScale : 1.0;
        final effectiveGridSize = calculateEffectiveGridSize(scale);
        final snappedPos = _snapToGrid(targetPos, effectiveGridSize);

        final newNodeId = ctx.onCreateNode(snappedPos);
        ctx.onRelationCreate(
          sourceId,
          newNodeId,
          fromSide: sourcePort?.side,
        );
      }
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, ctx, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = ctx.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = ctx.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            ctx.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }

    ctx.setHoveredNode(hoveredNodeId);

    ctx.onNodeDragUpdate();
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      initialCursorPosition: initialCursorPosition,
      snappedTargetNodeId: snappedId,
      sourcePort: sourcePort,
      snappedTargetPort: snappedPort,
    );
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    GeometryCapability ctx,
  ) {
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationSnapPreviewClear(sourceId);
      }
    }
    ctx.setHoveredNode(null);
    ctx.onNodeDragUpdate();
    return const CanvasIdle();
  }
}
