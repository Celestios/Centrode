// lib/features/graph/state/states/relation_drawing.dart
part of '../base_interaction_state.dart';

/// Logger for RelationDrawing state telemetry
final Logger _relationLog = Logger('RelationDrawing');

/// State when drawing a new relation between nodes.
///
/// Tracks the cursor position and performs L2 snapping to find target nodes.
/// Returns a new instance on each move to ensure ValueNotifier notifications
/// trigger UI rebuilds for the temporary relation line.
///
/// Supports multiple source nodes (multi-selection) and "Sticky" mode where
/// the state persists after creating a relation, allowing rapid successive
/// relation creation.
class RelationDrawing extends CanvasInteractionState {
  /// The set of source node IDs to create relations from.
  /// In sticky mode, this set is updated after each relation creation
  /// to contain only the last target node (which becomes the new source).
  final Set<String> sourceNodeIds;

  /// The current cursor position in canvas coordinates.
  final Offset currentCursorPosition;

  /// The currently snapped target node ID, if any.
  final String? snappedTargetNodeId;

  /// Whether sticky mode is active. In sticky mode:
  /// - Relations are created on pointer up without exiting the state
  /// - The target becomes the new source for the next relation
  /// - State only exits on explicit abort (secondary button or escape)
  final bool isSticky;

  /// Latch to track if the first release (toolbar button release) has occurred.
  /// In sticky mode, this prevents the initial toolbar button release from
  /// terminating the relation drawing state prematurely.
  final bool hasReleasedOnce;

  const RelationDrawing(
    this.sourceNodeIds,
    this.currentCursorPosition, {
    this.snappedTargetNodeId,
    this.isSticky = false,
    this.hasReleasedOnce = false,
  });

  /// Convenience constructor for single source node (non-sticky by default).
  factory RelationDrawing.single(
    String sourceNodeId,
    Offset currentCursorPosition, {
    bool isSticky = false,
  }) {
    return RelationDrawing(
      {sourceNodeId},
      currentCursorPosition,
      isSticky: isSticky,
    );
  }

  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
    bool isDoubleTap,
  ) {
    // Abort on Right-Click
    if (e.buttons == kSecondaryMouseButton) {
      return const CanvasIdle();
    }

    // If we are already in the "following" phase and have a snap target, commit on click
    if (isSticky && hasReleasedOnce && snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationCreate(sourceId, snappedTargetNodeId!);
      }
      return const CanvasIdle();
    }

    return this;
  }

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    GeometryCapability ctx,
  ) {
    // L2 Snapping Logic - find nearby target node
    String? snappedId;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      // Skip all source nodes
      if (sourceNodeIds.contains(nodeId)) continue;

      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      // Check distance to target's closest port
      final position = vs.getClosestPort(pCanvas).position;
      final dist = (pCanvas - position).distance;
      if (dist < AppConfig.interaction.snapDistance) {
        snappedId = nodeId;
        break;
      }
    }

    ctx.onNodeDragUpdate(); // Pulse MovementNotifier for relation layer repaints
    // Return new instance to trigger ValueNotifier notification
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      snappedTargetNodeId: snappedId,
      isSticky: isSticky,
      hasReleasedOnce: hasReleasedOnce,
    );
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    GeometryCapability ctx,
  ) {
    if (isSticky) {
      // First release (from the toolbar button): just flip the latch to start following
      if (!hasReleasedOnce) {
        _relationLog.fine(
          'Sticky Mode: Latch flipped (hasReleasedOnce=true). Now following cursor.',
        );
        return RelationDrawing(
          sourceNodeIds,
          currentCursorPosition,
          snappedTargetNodeId: snappedTargetNodeId,
          isSticky: true,
          hasReleasedOnce: true,
        );
      }
      // Subsequent releases in sticky mode are ignored; we wait for a PointerDown confirmation
      return this;
    }

    // Legacy drag-and-drop behavior (non-sticky) remains for other triggers
    if (snappedTargetNodeId != null) {
      for (final sourceId in sourceNodeIds) {
        ctx.onRelationCreate(sourceId, snappedTargetNodeId!);
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
    if (!isSticky) return this; // Opt-out if not in sticky mode

    // Duplicate L2 snapping logic to process free mouse movement
    String? snappedId;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      if (sourceNodeIds.contains(nodeId)) continue;
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      final position = vs.getClosestPort(pCanvas).position;
      if ((pCanvas - position).distance <
          AppConfig.interaction.snapDistance) {
        snappedId = nodeId;
        break;
      }
    }

    ctx.onNodeDragUpdate(); // Pulse MovementNotifier for layer repaints
    return RelationDrawing(
      sourceNodeIds,
      pCanvas,
      snappedTargetNodeId: snappedId,
      isSticky: isSticky,
      hasReleasedOnce: hasReleasedOnce,
    );
  }
}
