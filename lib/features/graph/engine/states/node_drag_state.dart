// lib/features/graph/state/states/node_dragging.dart
part of '../base_interaction_state.dart';

/// Logger for NodeDragging state telemetry
final Logger _nodeDragLog = Logger('NodeDragging');

/// State when a node is being dragged.
///
/// Updates the node position during drag and commits on pointer up.
/// The [grabOffset] ensures the cursor maintains relative position to the node.
class NodeDragging extends CanvasInteractionState {
  final RawUuid nodeId;
  Offset grabOffset;
  Timer? _snapTimer;
  Timer? _hoverHoldTimer;
  RawUuid? _hoveredContainerId;
  Offset? _lastScreenPosition;
  bool _isExitingContainer = false;
  bool _hasMoved = false;

  NodeDragging(this.nodeId, this.grabOffset);

  @override
  bool get allowsAutoPan => true;

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryAndViewportCapability;
    _hasMoved = true;
    _lastScreenPosition = e.position;
    final vs = c.nodeViewStates[nodeId];
    if (vs == null) {
      _snapTimer?.cancel();
      _hoverHoldTimer?.cancel();
      _nodeDragLog.severe(
        'Dangling Pointer: Dragging $nodeId but ViewState is null. Resetting to Idle.',
      );
      c.setNodeDragging(nodeId, false);
      return const CanvasIdle();
    }

    c.setNodeDragging(nodeId, true);
    final rawPos = pCanvas - (grabOffset * vs.visualScaleNotifier.value);
    final effectiveGridSize = calculateEffectiveGridSize(c.currentScale);
    final snappedPos = _snapToGrid(rawPos, effectiveGridSize);

    // Continuous visual movement
    vs.positionNotifier.value = rawPos;
    c.onNodesDrag([(nodeId, snappedPos)]);

    // Delayed grid snap when mouse pauses
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 150), () {
      vs.positionNotifier.value = snappedPos;
      c.onNodesDrag([(nodeId, snappedPos)]);
    });

    // Hover-Hold container detection (Outside -> Inside)
    final activeScope = c.activeScope;
    if (activeScope is RootViewportScope) {
      ContainerUiNode? hoveredContainer;
      for (final candidateId in c.nodeViewStates.keys) {
        if (candidateId == nodeId) continue;
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
        if (hoveredContainer.id != _hoveredContainerId) {
          _hoveredContainerId = hoveredContainer.id;
          _hoverHoldTimer?.cancel();
          final targetContainer = hoveredContainer;
          _hoverHoldTimer = Timer(const Duration(milliseconds: 750), () {
            final sx = 1600.0 / (targetContainer.size.width > 0 ? targetContainer.size.width : 1.0);
            final targetRatio = 1.0 / sx;

            c.openContainer(
              targetContainer,
              animate: true,
              onProgress: (t) {
                final visualScale = 1.0 + (targetRatio - 1.0) * t;
                vs.visualScaleNotifier.value = visualScale;

                final screenPos = _lastScreenPosition ?? Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
                final pCanvas = c.screenToCanvas(screenPos);
                final currentPos = pCanvas - (grabOffset * visualScale);
                vs.positionNotifier.value = currentPos;
                c.onNodesDrag([(nodeId, currentPos)]);
              },
              onComplete: () {
                vs.visualScaleNotifier.value = 1.0;
                final screenPos = _lastScreenPosition ?? Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
                final pContainerCanvas = c.screenToCanvas(screenPos);
                final newLocalPos = pContainerCanvas - grabOffset;

                c.reparentNode(nodeId, targetContainer.id, newLocalPos);
                vs.positionNotifier.value = newLocalPos;
                c.onNodesDrag([(nodeId, newLocalPos)]);
              },
            );
          });
        }
      } else {
        _hoverHoldTimer?.cancel();
        _hoveredContainerId = null;
      }
    } else if (activeScope is ContainerViewportScope && !_isExitingContainer) {
      // Boundary Escape detection (Inside -> Outside)
      final parentContainer = c.getNode(activeScope.containerId) as ContainerUiNode?;
      if (parentContainer != null) {
        final aspectRatio = parentContainer.size.height / (parentContainer.size.width > 0 ? parentContainer.size.width : 1.0);
        final internalW = 1600.0;
        final internalH = 1600.0 * aspectRatio;
        final internalRect = Rect.fromLTWH(0, 0, internalW, internalH);
        final nodeSize = vs.sizeNotifier.value;
        final nodeCenter = rawPos + Offset((nodeSize.width > 0 ? nodeSize.width : 160.0) / 2, (nodeSize.height > 0 ? nodeSize.height : 80.0) / 2);

        if (!internalRect.contains(nodeCenter)) {
          _isExitingContainer = true;
          _hoverHoldTimer?.cancel();
          _snapTimer?.cancel();

          final sx = 1600.0 / (parentContainer.size.width > 0 ? parentContainer.size.width : 1.0);
          final minScale = 1.0 / sx;

          c.closeContainer(
            parentContainer,
            animate: true,
            onProgress: (t) {
              final visualScale = minScale + (1.0 - minScale) * t;
              vs.visualScaleNotifier.value = visualScale;

              final screenPos = _lastScreenPosition ?? Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
              final pCanvas = c.screenToCanvas(screenPos);
              final currentPos = pCanvas - (grabOffset * visualScale);
              vs.positionNotifier.value = currentPos;
              c.onNodesDrag([(nodeId, currentPos)]);
            },
            onComplete: () {
              vs.visualScaleNotifier.value = 1.0;
              final screenPos = _lastScreenPosition ?? Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
              final pCanvas = c.screenToCanvas(screenPos);
              final currentPos = pCanvas - grabOffset;
              vs.positionNotifier.value = currentPos;
              c.onNodesDrag([(nodeId, currentPos)]);
              _isExitingContainer = false;
            },
          );

          // Immediately reparent to parent canvas in zoomed-in matrix at minScale
          final screenPos = _lastScreenPosition ?? Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
          final pRootCanvas = c.screenToCanvas(screenPos);
          final initialExitPos = pRootCanvas - (grabOffset * minScale);
          c.reparentNode(nodeId, parentContainer.parentContainerId, initialExitPos);
          vs.visualScaleNotifier.value = minScale;
          vs.positionNotifier.value = initialExitPos;
          c.onNodesDrag([(nodeId, initialExitPos)]);
        }
      }
    }

    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryAndViewportCapability;
    _snapTimer?.cancel();
    _hoverHoldTimer?.cancel();
    final vs = c.nodeViewStates[nodeId];
    if (vs != null) {
      vs.visualScaleNotifier.value = 1.0;
    }
    c.setNodeDragging(nodeId, false);
    if (vs != null && _hasMoved) {
      final effectiveGridSize = calculateEffectiveGridSize(c.currentScale);
      final snappedPos = _snapToGrid(vs.positionNotifier.value, effectiveGridSize);
      vs.positionNotifier.value = snappedPos;
      _nodeDragLog.info(
        'Drag Commit: ID=$nodeId, Final Position=$snappedPos',
      );

      c.onNodeMove(nodeId, snappedPos);
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) {
    final c = ctx as GeometryAndViewportCapability;
    _snapTimer?.cancel();
    _hoverHoldTimer?.cancel();
    final vs = c.nodeViewStates[nodeId];
    if (vs != null) {
      vs.visualScaleNotifier.value = 1.0;
    }
    c.setNodeDragging(nodeId, false);
    return const CanvasIdle();
  }
}
