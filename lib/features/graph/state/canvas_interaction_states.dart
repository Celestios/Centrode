// lib/features/graph/state/canvas_interaction_states.dart
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'interaction_context.dart';

/// Sealed base class for all canvas interaction states.
/// 
/// Implements the Gang of Four (GoF) State Pattern where each subclass
/// encapsulates specialized domain physics. The sealed modifier enables
/// exhaustive pattern matching for state transitions.
/// 
/// Each state handles its own event processing and returns the next state,
/// enabling polymorphic dispatch without switch statements in the controller.
sealed class CanvasInteractionState {
  const CanvasInteractionState();

  /// Handles pointer down events. Returns the next state after processing.
  /// Default implementation returns `this` (no state change).
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) => this;

  /// Handles pointer move events. Returns the next state after processing.
  /// Default implementation returns `this` (no state change).
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) => this;

  /// Handles pointer up events. Returns the next state after processing.
  /// Default implementation returns to [CanvasIdle].
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) => const CanvasIdle();

  /// Handles pointer cancel events. Returns the next state after processing.
  /// Default implementation returns to [CanvasIdle].
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) => const CanvasIdle();
}

/// The default idle state - no active interaction.
/// 
/// Performs hit-testing on pointer down to determine the next state:
/// - Port hit: transitions to [RelationDrawing]
/// - Node body hit: transitions to [NodeDragging]
/// - Double-tap: creates node (on canvas) or enters edit mode (on entity)
class CanvasIdle extends CanvasInteractionState {
  const CanvasIdle();

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    // Conflict Resolution: Commit active edits if clicking elsewhere
    final activeEditId = ctx.getActiveEditId();

    // Hit Testing Registry
    String? hitNodeId;
    bool hitPort = false;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      final nodeRect = vs.rect;

      // Port Hit-Test: Right Center Port (for relation drawing)
      if (Rect.fromCenter(
        center: nodeRect.centerRight,
        width: 30,
        height: 30,
      ).contains(pCanvas)) {
        hitNodeId = nodeId;
        hitPort = true;
        break;
      } else if (nodeRect.contains(pCanvas)) {
        hitNodeId = nodeId;
        break;
      }
    }

    // Relation label hit testing
    final hitEntityId = hitNodeId ?? _hitTestRelations(pCanvas, ctx);

    // Commit active edit if clicking elsewhere
    if (activeEditId != null && hitEntityId != activeEditId) {
      ctx.onCommitActiveEdit();
    }

    // Double Tap Execution
    if (isDoubleTap) {
      if (hitEntityId == null) {
        ctx.onCreateNode(pCanvas);
      } else {
        ctx.onEnterEditMode(hitEntityId);
      }
      return this;
    }

    // Standard Transitions
    if (hitNodeId != null) {
      if (hitPort) {
        return RelationDrawing(hitNodeId, pCanvas);
      } else {
        return NodeDragging(
          hitNodeId,
          pCanvas - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value,
        );
      }
    }

    return this;
  }

  /// Hit-tests relation labels at the midpoint between connected nodes.
  String? _hitTestRelations(Offset p, InteractionContext ctx) {
    for (final rel in ctx.getRelations()) {
      final fVs = ctx.nodeViewStates[rel.fromNodeId];
      final tVs = ctx.nodeViewStates[rel.toNodeId];
      if (fVs == null || tVs == null) continue;

      final start = fVs.positionNotifier.value +
          Offset(fVs.sizeNotifier.value.width,
              fVs.sizeNotifier.value.height / 2);
      final end = tVs.positionNotifier.value +
          Offset(0, tVs.sizeNotifier.value.height / 2);
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      if (Rect.fromCenter(center: mid, width: 100, height: 40).contains(p)) {
        return rel.id;
      }
    }
    return null;
  }
}

/// State when a node is being dragged.
/// 
/// Updates the node position during drag and commits on pointer up.
/// The [grabOffset] ensures the cursor maintains relative position to the node.
class NodeDragging extends CanvasInteractionState {
  final String nodeId;
  final Offset grabOffset;

  const NodeDragging(this.nodeId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle(); // Defensive check for dangling pointers
    vs.positionNotifier.value = pCanvas - grabOffset;
    ctx.onNodeDragUpdate();
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null) {
      ctx.onNodeMove(nodeId, vs.positionNotifier.value);
    }
    return const CanvasIdle();
  }
}

/// State when drawing a new relation between nodes.
/// 
/// Tracks the cursor position and performs L2 snapping to find target nodes.
/// Returns a new instance on each move to ensure ValueNotifier notifications
/// trigger UI rebuilds for the temporary relation line.
class RelationDrawing extends CanvasInteractionState {
  final String sourceNodeId;
  final Offset currentCursorPosition;
  final String? snappedTargetNodeId;

  const RelationDrawing(this.sourceNodeId, this.currentCursorPosition, {this.snappedTargetNodeId});

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    // L2 Snapping Logic - find nearby target node
    String? snappedId;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      if (nodeId == sourceNodeId) continue;

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      // Check distance to target's left port (centerLeft)
      final dist = (pCanvas - vs.rect.centerLeft).distance;
      if (dist < 40.0) {
        snappedId = nodeId;
        break;
      }
    }

    ctx.onNodeDragUpdate(); // Pulse MovementNotifier for relation layer repaints
    // Return new instance to trigger ValueNotifier notification
    return RelationDrawing(sourceNodeId, pCanvas, snappedTargetNodeId: snappedId);
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    if (snappedTargetNodeId != null) {
      ctx.onRelationCreate(sourceNodeId, snappedTargetNodeId!);
    }
    return const CanvasIdle();
  }
}
