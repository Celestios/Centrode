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
    // Conflict Resolution: Commit active edits if clicking elsewhere
    final activeEditId = ctx.getActiveEditId();

    // Priority -1: Right-Click Marquee Routing
    if (e.buttons == kSecondaryMouseButton) {
      _canvasIdleLog.fine(
        'Right-click detected: Transitioning to MarqueeSelecting',
      ); // [NEW]
      return MarqueeSelecting(pCanvas, pCanvas);
    }

    // Priority 0: Floating Toolbar Hit-Testing (Absolute Top)
    // Supports both single-selection, multi-selection, and relation toolbars
    final selectedEntities = ctx.getSelectedEntities();
    if (selectedEntities.isNotEmpty) {
      final isMultiSelect = selectedEntities.length > 1;
      Offset? anchorTopLeft;
      bool isRelationOnly = false;

      if (isMultiSelect) {
        // Calculate mathematically accurate Canvas Space Bounding Box
        double minX = double.infinity,
            minY = double.infinity,
            maxX = double.negativeInfinity,
            maxY = double.negativeInfinity;
        for (final id in selectedEntities) {
          final viewState = ctx.nodeViewStates[id];
          if (viewState == null) continue;
          final rect = viewState.rect;
          if (rect.left < minX) minX = rect.left;
          if (rect.top < minY) minY = rect.top;
          if (rect.right > maxX) maxX = rect.right;
          if (rect.bottom > maxY) maxY = rect.bottom;
        }
        // Center horizontally above the bounding box
        final centerX = minX + (maxX - minX) / 2;
        anchorTopLeft = Offset(
          centerX - (AppConfig.toolbar.multiWidth / 2),
          minY - AppConfig.toolbar.height - 10,
        );
      } else {
        // Single selection: check if it's a node or a relation
        final vs = ctx.nodeViewStates[selectedEntities.first];
        if (vs != null) {
          anchorTopLeft = vs.positionNotifier.value;
        } else {
          // Fallback: Check if it's a relation - calculate midpoint anchor
          try {
            final rel = ctx.getRelations().firstWhere(
              (r) => r.id == selectedEntities.first,
            );
            final sourceVs = ctx.nodeViewStates[rel.fromNodeId];
            final targetVs = ctx.nodeViewStates[rel.toNodeId];
            if (sourceVs != null && targetVs != null) {
              final start = sourceVs.rightPort;
              final end = targetVs.leftPort;
              anchorTopLeft = Offset(
                (start.dx + end.dx) / 2,
                (start.dy + end.dy) / 2,
              );
              isRelationOnly = true;
            }
          } catch (_) {}
        }
      }

      // Do not short-circuit if it's a relation - continue to toolbar hit-test
      if (anchorTopLeft != null) {
        final tbOffset = ctx.getToolbarOffset();
        final toolbarTopLeft = anchorTopLeft + tbOffset;

        // Use appropriate toolbar width based on selection type
        double toolbarWidth = AppConfig.toolbar.singleWidth;
        if (isMultiSelect) {
          toolbarWidth = AppConfig.toolbar.multiWidth;
        } else if (isRelationOnly) {
          toolbarWidth =
              AppConfig.toolbar.buttonWidth *
              2; // 2-button toolbar for relations
        }

        // Exact geometric bounds of the toolbar
        final toolbarRect = Rect.fromLTWH(
          toolbarTopLeft.dx,
          toolbarTopLeft.dy,
          toolbarWidth,
          AppConfig.toolbar.height,
        );

        if (toolbarRect.contains(pCanvas)) {
          _canvasIdleLog.info(
            'Toolbar Hit: Entity ${selectedEntities.first} at $pCanvas',
          ); // [NEW]
          final localX = pCanvas.dx - toolbarTopLeft.dx;
          final btnWidth = AppConfig.toolbar.buttonWidth;

          if (isRelationOnly) {
            // Relation toolbar: Zone 1 (Drag), Zone 2 (Delete) - Link is omitted
            if (localX < btnWidth) {
              // Zone 1: Drag (toolbar repositioning)
              return ToolbarDragging(
                selectedEntities.first,
                pCanvas - toolbarTopLeft,
              );
            } else {
              // Zone 2: Delete
              ctx.onDeleteSelectedEntities();
              return const CanvasIdle();
            }
          } else {
            // Node toolbar: 3-zone logic
            if (localX < btnWidth) {
              // Zone 1: Drag (toolbar repositioning)
              return ToolbarDragging(
                selectedEntities.first,
                pCanvas - toolbarTopLeft,
              );
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
    }

    // Hit Testing Registry
    String? hitNodeId;
    bool hitResize = false;
    ResizeEdge? draggedEdge;
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    int zeroSizeRejections = 0; // Track Size.zero bypasses

    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null) continue;
      if (vs.sizeNotifier.value == Size.zero) {
        zeroSizeRejections++;
        continue;
      }

      final nodeRect = vs.rect;

      // Priority 0.5: Expand Toggle Hit-Test
      if (vs.lineCount > 3 && vs.expandToggleHitbox.contains(pCanvas)) {
        _canvasIdleLog.fine('Expand Toggle Hit: $nodeId'); // [NEW]
        ctx.toggleNodeExpansion(nodeId);
        return this; // Intercept and abort further drag/selection evaluation
      }

      // Priority 1: Resize Edge Hit-Test (Rightmost / Leftmost 15 logical pixels)
      if (vs.rightResizeHitbox.contains(pCanvas)) {
        hitNodeId = nodeId;
        hitResize = true;
        draggedEdge = ResizeEdge.right;
        break;
      } else if (vs.leftResizeHitbox.contains(pCanvas)) {
        hitNodeId = nodeId;
        hitResize = true;
        draggedEdge = ResizeEdge.left;
        break;
      }
      // Priority 2: Body Hit-Test (Standard Dragging)
      else if (nodeRect.contains(pCanvas)) {
        hitNodeId = nodeId;
        break;
      }
    }

    if (zeroSizeRejections > 0) {
      _canvasIdleLog.finer(
        'Hit-Test bypass: Ignored $zeroSizeRejections nodes due to Size.zero bounding boxes.',
      );
    }

    // Relation label hit testing
    final hitEntityId = hitNodeId ?? _hitTestRelations(pCanvas, ctx);

    // Commit active edit if clicking elsewhere or if clicking a resize handle of the edited node
    if (activeEditId != null && (hitEntityId != activeEditId || hitResize)) {
      ctx.onCommitActiveEdit();
    }

    // Fire selection intent immediately on pointer down.
    // If hitEntityId is null (clicked empty canvas), it clears the selection.
    _canvasIdleLog.fine('Selection Intent: HitEntity=$hitEntityId'); // [NEW]
    ctx.onSelectEntity(hitEntityId);

    // THE FIX: Complete FSM Shielding for the active editor.
    // If the user clicks inside the node currently being edited (and not on its resize handles),
    // abort FSM processing to let native Flutter TextField own the gesture arena.
    if (hitEntityId != null && hitEntityId == activeEditId && !hitResize) {
      _canvasIdleLog.finer(
        'FSM Shielding Active: Event absorbed by Editor for $hitEntityId',
      ); // [NEW]
      return this;
    }

    // Double Tap Execution
    if (isDoubleTap) {
      if (hitEntityId == null) {
        _canvasIdleLog.info(
          'Double-tap Creation: Snapped position calculated.',
        ); // [NEW]
        // Quantize node creation coordinates using Dynamic LOD
        final effectiveGridSize = calculateEffectiveGridSize(ctx.currentScale);
        final snappedPos = _snapToGrid(pCanvas, effectiveGridSize);
        ctx.onCreateNode(snappedPos);
      } else {
        ctx.onEnterEditMode(hitEntityId);
      }
      return this;
    }

    // Standard Transitions
    if (hitNodeId != null) {
      if (hitResize && draggedEdge != null) {
        final vs = ctx.nodeViewStates[hitNodeId]!;
        final initialLeft = vs.positionNotifier.value.dx;
        final initialWidth = vs.sizeNotifier.value.width;
        final double grabOffsetX;
        if (draggedEdge == ResizeEdge.right) {
          grabOffsetX = pCanvas.dx - (initialLeft + initialWidth);
        } else {
          grabOffsetX = pCanvas.dx - initialLeft;
        }

        // Route to Resizing State
        return NodeResizing(
          hitNodeId,
          draggedEdge,
          grabOffsetX,
          initialLeft,
          initialWidth,
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

      // Using DRY Geometry
      final start = fVs.rightPort;
      final end = tVs.leftPort;
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      if (Rect.fromCenter(
        center: mid,
        width: AppConfig.interaction.relationLabelHitArea.width,
        height: AppConfig.interaction.relationLabelHitArea.height,
      ).contains(p)) {
        return rel.id;
      }
    }
    return null;
  }

  @override
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      if (vs.rightResizeHitbox.contains(pCanvas) ||
          vs.leftResizeHitbox.contains(pCanvas)) {
        return cursor == SystemMouseCursors.resizeLeftRight
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.resizeLeftRight);
      }

      if (vs.lineCount > 3 && vs.expandToggleHitbox.contains(pCanvas)) {
        return cursor == SystemMouseCursors.click
            ? this
            : CanvasIdle(cursor: SystemMouseCursors.click);
      }
    }

    return cursor == SystemMouseCursors.basic
        ? this
        : CanvasIdle(cursor: SystemMouseCursors.basic);
  }
}
