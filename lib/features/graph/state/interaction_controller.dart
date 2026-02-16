import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../domain/models.dart';

/// The Interaction Controller (FSM Engine)
///
/// This engine circumvents the Gesture Arena by processing raw PointerEvents.
/// It centralizes all pointer events into a math-driven FSM that operates in
/// canvas space, decoupling user intent from the Flutter Widget tree.
class InteractionController {
  final Logger _log = Logger('InteractionController');

  /// The current interaction state of the canvas.
  final ValueNotifier<CanvasInteractionState> state =
      ValueNotifier(const CanvasIdle());

  /// Controller for canvas transformations (pan/zoom).
  final TransformationController transformController;

  /// Registry of all node view states for hit-testing.
  final Map<String, NodeViewState> nodeViewStates;

  /// Callback when a node move operation completes.
  final Function(String id, Offset pos) onNodeMove;

  /// Callback when a relation is created between two nodes.
  final Function(String from, String to) onRelationCreate;

  /// Callback to trigger relation layer repaint during node drag.
  final VoidCallback onNodeDragUpdate;

  /// Z-order tracking for proper hit-testing (last item is topmost).
  final List<String> _zOrder = [];

  InteractionController({
    required this.transformController,
    required this.nodeViewStates,
    required this.onNodeMove,
    required this.onRelationCreate,
    required this.onNodeDragUpdate,
  });

  /// Centralized state mutation to guarantee FSM observability.
  /// Logs state transitions for telemetry and debugging purposes.
  void _transitionTo(CanvasInteractionState newState) {
    if (state.value.runtimeType != newState.runtimeType) {
      _log.fine('FSM Transition: ${state.value.runtimeType} -> ${newState.runtimeType}');
    }
    state.value = newState;
  }

  /// Updates the z-order list. Call this when nodes are added/removed/reordered.
  void updateZOrder(List<String> newOrder) {
    _zOrder
      ..clear()
      ..addAll(newOrder);
  }

  /// Converts a screen position to canvas coordinates.
  Offset _screenToCanvas(Offset screenPos) {
    final transform = transformController.value;
    
    // Guard against singular matrix (scale = 0)
    if (transform.determinant() == 0.0) return screenPos;

    return MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      screenPos,
    );
  }

  /// Handles pointer down events. Performs hit-testing to determine interaction.
  void handlePointerDown(PointerDownEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);

    // Z-index descending check (topmost first)
    final nodeIds = _zOrder.isNotEmpty ? _zOrder.reversed : nodeViewStates.keys.toList().reversed;
    
    for (final nodeId in nodeIds) {
      final vs = nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      final nodeRect = vs.rect;
      
      // Port Hit-Test: Right Center Port (for relation drawing)
      final portRect = Rect.fromCenter(
        center: nodeRect.centerRight,
        width: 30,
        height: 30,
      );

      if (portRect.contains(pCanvas)) {
        // Start drawing a relation from this node's port
        _transitionTo(RelationDrawing(nodeId, pCanvas));
        return;
      } else if (nodeRect.contains(pCanvas)) {
        // Start dragging this node
        _transitionTo(NodeDragging(nodeId, pCanvas - vs.positionNotifier.value));
        return;
      }
    }
    
    // No hit - return to idle
    _transitionTo(const CanvasIdle());
  }

  /// Handles pointer move events. Updates the current interaction state.
  void handlePointerMove(PointerMoveEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    final current = state.value;

    if (current is NodeDragging) {
      // Update node position during drag
      final vs = nodeViewStates[current.nodeId];
      if (vs != null) {
        vs.positionNotifier.value = pCanvas - current.grabOffset;
        onNodeDragUpdate(); // Forces relation layer to repaint instantly
      }
    } else if (current is RelationDrawing) {
      // L2 Snapping Logic - find nearby target node
      String? snappedId;
      final nodeIds = _zOrder.isNotEmpty 
          ? _zOrder.reversed 
          : nodeViewStates.keys.toList().reversed;
      
      for (final nodeId in nodeIds) {
        if (nodeId == current.sourceNodeId) continue;
        
        final vs = nodeViewStates[nodeId];
        if (vs == null) continue;
        if (vs.sizeNotifier.value == Size.zero) continue;

        // Check distance to target's left port (centerLeft)
        final dist = (pCanvas - vs.rect.centerLeft).distance;
        if (dist < 40.0) {
          snappedId = nodeId;
          break;
        }
      }
      
      // Only log L2 Snapping if it actually changes target state to avoid log flooding
      if (snappedId != current.snappedTargetNodeId) {
        if (snappedId != null) _log.finer('Relation snapped to target: $snappedId');
      }
      
      _transitionTo(RelationDrawing(
        current.sourceNodeId,
        pCanvas,
        snappedTargetNodeId: snappedId,
      ));
    }
  }

  /// Handles pointer up events. Finalizes the current interaction.
  void handlePointerUp(PointerUpEvent e) {
    final current = state.value;

    if (current is NodeDragging) {
      // Finalize node position
      final vs = nodeViewStates[current.nodeId];
      if (vs != null) {
        onNodeMove(current.nodeId, vs.positionNotifier.value);
      }
    } else if (current is RelationDrawing) {
      // Create relation if we have a valid target
      if (current.snappedTargetNodeId != null) {
        onRelationCreate(current.sourceNodeId, current.snappedTargetNodeId!);
      }
    }
    
    // Return to idle state
    _transitionTo(const CanvasIdle());
  }

  /// Handles pointer cancel events. Resets to idle without finalizing.
  void handlePointerCancel(PointerCancelEvent e) {
    _log.warning('Pointer event cancelled by OS. Resetting FSM to Idle.');
    _transitionTo(const CanvasIdle());
  }

  /// Disposes the state notifier.
  void dispose() {
    state.dispose();
  }
}
