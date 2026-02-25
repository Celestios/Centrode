// lib/features/graph/state/canvas_interaction_states.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
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

    // Priority -1: Right-Click Marquee Routing
    if (e.buttons == kSecondaryMouseButton) {
      return MarqueeSelecting(pCanvas, pCanvas);
    }

    // Priority 0: Floating Toolbar Hit-Testing (Absolute Top)
    // Supports both single-selection and multi-selection toolbars
    final selectedEntities = ctx.getSelectedEntities();
    if (selectedEntities.isNotEmpty) {
      // For multi-selection, use the first selected node's position as anchor
      // (or compute bounding box center in a more sophisticated implementation)
      final anchorId = selectedEntities.first;
      final vs = ctx.nodeViewStates[anchorId];
      if (vs != null) {
        final isMultiSelect = selectedEntities.length > 1;
        final tbOffset = ctx.getToolbarOffset();
        final toolbarTopLeft = vs.positionNotifier.value + tbOffset;

        // Use appropriate toolbar width based on selection count
        final toolbarWidth = isMultiSelect
            ? AppConfig.graph.toolbar.multiWidth
            : AppConfig.graph.toolbar.singleWidth;

        // Exact geometric bounds of the toolbar
        final toolbarRect = Rect.fromLTWH(
          toolbarTopLeft.dx,
          toolbarTopLeft.dy,
          toolbarWidth,
          AppConfig.graph.toolbar.height,
        );

        if (toolbarRect.contains(pCanvas)) {
          final localX = pCanvas.dx - toolbarTopLeft.dx;
          final btnWidth = AppConfig.graph.toolbar.buttonWidth;

          if (localX < btnWidth) {
            // Zone 1: Drag (toolbar repositioning)
            return ToolbarDragging(anchorId, pCanvas - toolbarTopLeft);
          } else if (localX < btnWidth * 2) {
            // Zone 2: Link (New Relation) - enters sticky RelationDrawing mode
            return RelationDrawing(selectedEntities, pCanvas, isSticky: true);
          } else {
            // Zone 3: Delete
            ctx.onDeleteSelectedEntities();
            return const CanvasIdle();
          }
        }
      }
    }

    // Hit Testing Registry
    String? hitNodeId;
    bool hitResize = false;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) continue;

      final nodeRect = vs.rect;

      // Priority 1: Resize Edge Hit-Test (Rightmost 15 logical pixels)
      if (vs.resizeHitbox.contains(pCanvas)) {
        // [REFACTORED]
        hitNodeId = nodeId;
        hitResize = true;
        break;
      }
      // Priority 2: Body Hit-Test (Standard Dragging)
      else if (nodeRect.contains(pCanvas)) {
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

    // Fire selection intent immediately on pointer down.
    // If hitEntityId is null (clicked empty canvas), it clears the selection.
    ctx.onSelectEntity(hitEntityId);

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
      if (hitResize) {
        // Route to Resizing State
        return NodeResizing(
          hitNodeId,
          pCanvas.dx - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value.dx,
        );
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

      // [REFACTORED]: Use DRY Geometry
      final start = fVs.rightPort;
      final end = tVs.leftPort;
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      if (Rect.fromCenter(
        center: mid,
        width: AppConfig.graph.interaction.relationLabelHitArea.width,
        height: AppConfig.graph.interaction.relationLabelHitArea.height,
      ).contains(p)) {
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
    if (vs == null) {
      return const CanvasIdle(); // Defensive check for dangling pointers
    }
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
    InteractionContext ctx,
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
    InteractionContext ctx,
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

      // Check distance to target's left port (centerLeft)
      final dist = (pCanvas - vs.leftPort).distance;
      if (dist < AppConfig.graph.interaction.snapDistance) {
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
    InteractionContext ctx,
  ) {
    if (isSticky) {
      // First release (from the toolbar button): just flip the latch to start following
      if (!hasReleasedOnce) {
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
}

/// [NEW] State when dragging the right edge of a node to resize its width.
/// Operates exclusively in visual memory until PointerUp, where it commits the DB patch.
class NodeResizing extends CanvasInteractionState {
  final String nodeId;
  final double grabOffsetX;

  const NodeResizing(this.nodeId, this.grabOffsetX);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle();

    // Calculate new width: Current pointer X minus the Node's original Left X
    double newWidth = pCanvas.dx - vs.positionNotifier.value.dx;
    if (newWidth < AppConfig.graph.node.minWidth) {
      newWidth = AppConfig.graph.node.minWidth;
    } // Minimum width safety constraint

    vs.dragWidthNotifier.value = newWidth;

    // Trigger repaint for the relation layer
    ctx.onNodeDragUpdate();
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs != null && vs.dragWidthNotifier.value != null) {
      ctx.onNodeResizeEnd(nodeId, vs.dragWidthNotifier.value!);
      vs.dragWidthNotifier.value = null; // Clear volatile drag state
    }
    return const CanvasIdle();
  }
}

/// [NEW] State when dragging the floating toolbar to adjust its relative offset.
class ToolbarDragging extends CanvasInteractionState {
  final String nodeId;
  final Offset grabOffset; // Pointer offset relative to the toolbar's top-left

  const ToolbarDragging(this.nodeId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return const CanvasIdle();

    // Calculate new absolute position of the toolbar
    final newAbsolutePos = pCanvas - grabOffset;

    // Calculate new relative offset from the node's position
    final newRelativeOffset = newAbsolutePos - vs.positionNotifier.value;

    ctx.updateToolbarOffset(newRelativeOffset);
    return this;
  }
}

/// State when dragging a marquee selection box via right-click.
/// Computes overlaps against visible nodes in O(V) time upon release.
class MarqueeSelecting extends CanvasInteractionState {
  final Offset startPos;
  final Offset currentPos;

  const MarqueeSelecting(this.startPos, this.currentPos);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    // Return new instance to trigger CustomPaint redraw
    return MarqueeSelecting(startPos, pCanvas);
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final marqueeRect = Rect.fromPoints(startPos, currentPos);
    final visibleIds = ctx.getVisibleNodeIds();
    final Set<String> hits = {};

    for (final id in visibleIds) {
      final vs = ctx.nodeViewStates[id];
      if (vs != null && vs.rect.overlaps(marqueeRect)) {
        hits.add(id);
      }
    }

    ctx.onSelectEntities(hits);
    return const CanvasIdle();
  }
}
