part of '../base_interaction_state.dart';

class RelationDrawing extends CanvasInteractionState {
  final Set<RawUuid> sourceNodeIds;
  final Offset currentCursorPosition;
  final Offset initialCursorPosition;
  final RawUuid? snappedTargetNodeId;
  final Port? sourcePort;
  final Port? snappedTargetPort;
  final Timer? hoverHoldTimer;
  final RawUuid? hoveredContainerId;

  const RelationDrawing(
    this.sourceNodeIds,
    this.currentCursorPosition, {
    Offset? initialCursorPosition,
    this.snappedTargetNodeId,
    this.sourcePort,
    this.snappedTargetPort,
    this.hoverHoldTimer,
    this.hoveredContainerId,
  }) : initialCursorPosition = initialCursorPosition ?? currentCursorPosition;

  @override
  bool get allowsAutoPan => true;

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    return this;
  }

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryCapability;
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, c, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = c.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = c.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            c.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
              sourceSide: sourcePort?.side,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        c.onRelationSnapPreviewClear(sourceId);
      }
    }

    Timer? nextHoverHoldTimer = hoverHoldTimer;
    RawUuid? nextHoveredContainerId = hoveredContainerId;

    final activeScope = c.activeScope;
    if (activeScope is RootViewportScope) {
      ContainerUiNode? hoveredContainer;
      for (final candidateId in c.nodeViewStates.keys) {
        if (sourceNodeIds.contains(candidateId)) continue;
        final candNode = c.getNode(candidateId);
        if (candNode is! ContainerUiNode) continue;
        if (candNode.parentContainerId != null) continue;
        final candVs = c.nodeViewStates[candidateId];
        if (candVs != null && candVs.rect.contains(pCanvas)) {
          hoveredContainer = candNode;
          break;
        }
      }

      if (hoveredContainer != null) {
        if (hoveredContainer.id != hoveredContainerId) {
          nextHoveredContainerId = hoveredContainer.id;
          nextHoverHoldTimer?.cancel();
          final targetContainer = hoveredContainer;
          nextHoverHoldTimer = Timer(const Duration(milliseconds: 750), () {
            c.openContainer(targetContainer, animate: true);
          });
        }
      } else {
        nextHoverHoldTimer?.cancel();
        nextHoverHoldTimer = null;
        nextHoveredContainerId = null;
      }
    }

    c.setHoveredNode(hoveredNodeId);
    c.onNodeDragUpdate();
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      initialCursorPosition: initialCursorPosition,
      snappedTargetNodeId: snappedId,
      sourcePort: sourcePort,
      snappedTargetPort: snappedPort,
      hoverHoldTimer: nextHoverHoldTimer,
      hoveredContainerId: nextHoveredContainerId,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    hoverHoldTimer?.cancel();
    final c = ctx as GeometryCapability;
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        c.onRelationSnapPreviewClear(sourceId);
        c.onRelationCreate(
          sourceId,
          snappedTargetNodeId!,
          fromSide: sourcePort?.side,
          toSide: snappedTargetPort?.side,
        );
      }
    } else if (sourceNodeIds.isNotEmpty) {
      for (final sourceId in sourceNodeIds) {
        c.onRelationSnapPreviewClear(sourceId);

        final sourceVs = c.nodeViewStates[sourceId];
        final sourceNode = c.getNode(sourceId);
        final sourcePos = sourceNode?.position ??
            (sourceVs != null ? sourceVs.positionNotifier.value : Offset.zero);
        final sourceSize =
            sourceVs?.sizeNotifier.value ?? const Size(160, 80);

        final isTap =
            (currentCursorPosition - initialCursorPosition).distance < 8.0;
        final Offset targetPos;

        if (isTap && sourcePort != null) {
          const baseCardinalSpacing = 200.0;
          const baseDiagSpacing = 100.0;

          final widthFactor = (sourceSize.width / 160.0).clamp(1.0, 4.0);
          final heightFactor = (sourceSize.height / 80.0).clamp(1.0, 4.0);

          final cardinalX =
              (baseCardinalSpacing * widthFactor / 20.0).round() * 20.0;
          final cardinalY =
              (baseCardinalSpacing * heightFactor / 20.0).round() * 20.0;
          final diagX = (baseDiagSpacing * widthFactor / 20.0).round() * 20.0;
          final diagY = (baseDiagSpacing * heightFactor / 20.0).round() * 20.0;

          switch (sourcePort!.side) {
            case PortSide.right:
              targetPos = sourcePos + Offset(sourceSize.width + cardinalX, 0);
              break;
            case PortSide.left:
              targetPos = sourcePos - Offset(160.0 + cardinalX, 0);
              break;
            case PortSide.bottom:
              targetPos = sourcePos + Offset(0, sourceSize.height + cardinalY);
              break;
            case PortSide.top:
              targetPos = sourcePos - Offset(0, 80.0 + cardinalY);
              break;
            case PortSide.topRight:
              targetPos = sourcePos +
                  Offset(
                    sourceSize.width + diagX,
                    -(80.0 + diagY),
                  );
              break;
            case PortSide.topLeft:
              targetPos = sourcePos +
                  Offset(-(160.0 + diagX), -(80.0 + diagY));
              break;
            case PortSide.bottomRight:
              targetPos = sourcePos +
                  Offset(
                    sourceSize.width + diagX,
                    sourceSize.height + diagY,
                  );
              break;
            case PortSide.bottomLeft:
              targetPos = sourcePos +
                  Offset(
                    -(160.0 + diagX),
                    sourceSize.height + diagY,
                  );
              break;
            case PortSide.auto:
              targetPos = sourcePos + Offset(sourceSize.width + cardinalX, 0);
              break;
          }
        } else {
          targetPos = currentCursorPosition;
        }

        final double scale = c.currentScale;
        final effectiveGridSize = calculateEffectiveGridSize(scale);
        final snappedPos = _snapToGrid(targetPos, effectiveGridSize);

        final PortSide? targetSide;
        if (isTap && sourcePort != null) {
          targetSide = switch (sourcePort!.side) {
            PortSide.right => PortSide.left,
            PortSide.left => PortSide.right,
            PortSide.bottom => PortSide.top,
            PortSide.top => PortSide.bottom,
            PortSide.topRight => PortSide.bottomLeft,
            PortSide.topLeft => PortSide.bottomRight,
            PortSide.bottomRight => PortSide.topLeft,
            PortSide.bottomLeft => PortSide.topRight,
            PortSide.auto => PortSide.left,
          };
        } else {
          final delta = snappedPos - sourcePos;
          if (delta.dx.abs() > delta.dy.abs()) {
            targetSide = delta.dx >= 0 ? PortSide.left : PortSide.right;
          } else {
            targetSide = delta.dy >= 0 ? PortSide.top : PortSide.bottom;
          }
        }

        final newNodeId = c.onCreateNode(snappedPos);
        c.onRelationCreate(
          sourceId,
          newNodeId,
          fromSide: sourcePort?.side,
          toSide: targetSide,
        );
      }
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryCapability;
    final prevSnappedId = snappedTargetNodeId;
    final snap = findNearestSnap(pCanvas, c, sourceNodeIds);
    final snappedId = snap.snappedNodeId;
    final snappedPort = snap.snappedPort;
    final hoveredNodeId = snap.hoveredNodeId;

    if (snappedId != null) {
      if (snappedId != prevSnappedId || snappedPort != snappedTargetPort) {
        final targetVs = c.nodeViewStates[snappedId];
        if (targetVs != null) {
          final targetNode = c.getNode(snappedId);
          final overridePos = snappedPort?.position ?? targetVs.rect.center;
          for (final sourceId in sourceNodeIds) {
            c.onRelationSnapPreview(
              relationId: sourceId,
              isStartTip: false,
              targetNodeId: snappedId,
              targetNodeTable: targetNode?.tableName ?? 'Nodes',
              targetSide: snappedPort?.side,
              overridePosition: overridePos,
              sourceSide: sourcePort?.side,
            );
          }
        }
      }
    } else if (snappedId == null && prevSnappedId != null) {
      for (final sourceId in sourceNodeIds) {
        c.onRelationSnapPreviewClear(sourceId);
      }
    }

    c.setHoveredNode(hoveredNodeId);

    c.onNodeDragUpdate();
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
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryCapability;
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        c.onRelationSnapPreviewClear(sourceId);
      }
    }
    c.setHoveredNode(null);
    c.onNodeDragUpdate();
    return const CanvasIdle();
  }
}
