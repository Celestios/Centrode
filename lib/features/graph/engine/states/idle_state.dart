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

  // TODO: this function seems like a mess
  @override
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    // Conflict Resolution: Commit active edits if clicking elsewhere
    final activeEditId = ctx.getActiveEditId();

    final layoutContext = RelationLayoutContext(
      nodeViewStates: ctx.nodeViewStates,
      relations: ctx.getRelations().toList(),
      pathCache: ctx.relationPathCache,
    );

    // Priority -1: Right-Click Marquee Routing
    if (e.buttons == kSecondaryMouseButton) {
      _canvasIdleLog.fine(
        'Right-click detected: Transitioning to MarqueeSelecting',
      ); // [NEW]
      return MarqueeSelecting(pCanvas, pCanvas);
    }

    // Priority -0.5: Selected Relation Tip Handles Hit-Testing
    final selectedEntities = ctx.getSelectedEntities();
    for (final id in selectedEntities) {
      UiRelation? rel;
      for (final r in ctx.getRelations()) {
        if (r.id == id) {
          rel = r;
          break;
        }
      }
      if (rel == null) continue;

      final from = ctx.nodeViewStates[rel.fromNodeId];
      final to = ctx.nodeViewStates[rel.toNodeId];
      if (from == null || to == null) continue;

      final layoutStrategy = RelationLayoutStrategy.fromType(rel.layout?.strategyType);
      final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(rel, from, to, layoutContext);
      if ((pCanvas - handleStart).distance < 12.0) {
        _canvasIdleLog.fine('Relation start tip handle hit: $id');
        return RelationTipDragging(
          relationId: rel.id,
          isStartTip: true,
          originalPosition: handleStart,
          currentCursorPosition: pCanvas,
        );
      } else if ((pCanvas - handleEnd).distance < 12.0) {
        _canvasIdleLog.fine('Relation end tip handle hit: $id');
        return RelationTipDragging(
          relationId: rel.id,
          isStartTip: false,
          originalPosition: handleEnd,
          currentCursorPosition: pCanvas,
        );
      }
    }

    // Priority 0: Floating Toolbar Hit-Testing (Absolute Top)
    // Supports both single-selection, multi-selection, and relation toolbars
    if (selectedEntities.isNotEmpty) {
      final isMultiSelect = selectedEntities.length > 1;
      final anchorTopLeft = ctx.calculateToolbarAnchor(selectedEntities);
      final isRelationOnly = !isMultiSelect && !ctx.nodeViewStates.containsKey(selectedEntities.first);

      // Do not short-circuit if it's a relation - continue to toolbar hit-test
      if (anchorTopLeft != null) {
        final tbOffset = ctx.getToolbarOffset();
        final toolbarTopLeft = anchorTopLeft + tbOffset;

        // Use appropriate toolbar width based on selection type and template availability
        final nodeIds = selectedEntities
            .where((id) => ctx.nodeViewStates.containsKey(id))
            .toList();
        final canSaveTemplate = nodeIds.isNotEmpty;

        double toolbarWidth = isMultiSelect
            ? AppConfig.toolbar.multiWidth
            : AppConfig.toolbar.singleWidth;

        if (isRelationOnly) {
          toolbarWidth = AppConfig.toolbar.buttonWidth * 2; // Only Drag and Delete
        } else if (canSaveTemplate) {
          toolbarWidth += AppConfig.toolbar.buttonWidth;
        }

        final double toolbarHeight = (canSaveTemplate && !isMultiSelect)
            ? AppConfig.toolbar.height * 2
            : AppConfig.toolbar.height;

        // Exact geometric bounds of the toolbar
        final toolbarRect = Rect.fromLTWH(
          toolbarTopLeft.dx,
          toolbarTopLeft.dy,
          toolbarWidth,
          toolbarHeight,
        );

        if (toolbarRect.contains(pCanvas)) {
          _canvasIdleLog.info(
            'Toolbar Hit: Entity ${selectedEntities.first} at $pCanvas',
          ); // [NEW]
          final localX = pCanvas.dx - toolbarTopLeft.dx;
          final localY = pCanvas.dy - toolbarTopLeft.dy;

          if (canSaveTemplate && !isMultiSelect) {
            // Two-row single node selection toolbar (120x64)
            final double btnWidth = toolbarWidth / 4; // 4 buttons per row (30px each)
            if (localY < AppConfig.toolbar.height) {
              // Row 1 (Top): Formatting (Decrease Font Size, Increase Font Size, Toggle Font Family, Cycle Text Color)
              final clickedButtonIndex = (localX / btnWidth).floor().clamp(0, 3);
              final nodeId = selectedEntities.first;

              if (clickedButtonIndex == 0) {
                // Decrease Font Size
                ctx.updateNodeStyle(nodeId, (style) {
                  final newSize = (style.fontSize - 2.0).clamp(8.0, 24.0);
                  return style.copyWith(fontSize: newSize);
                });
              } else if (clickedButtonIndex == 1) {
                // Increase Font Size
                ctx.updateNodeStyle(nodeId, (style) {
                  final newSize = (style.fontSize + 2.0).clamp(8.0, 24.0);
                  return style.copyWith(fontSize: newSize);
                });
              } else if (clickedButtonIndex == 2) {
                // Toggle Font Family
                ctx.updateNodeStyle(nodeId, (style) {
                  final newFont = style.fontFamily == 'Roboto' ? 'Inter' : 'Roboto';
                  return style.copyWith(fontFamily: newFont);
                });
              } else if (clickedButtonIndex == 3) {
                // Cycle Text Color
                const textColors = [
                  0xFF000000, // Black
                  0xFFFFFFFF, // White
                  0xFF0D47A1, // Dark Blue
                  0xFF1B5E20, // Dark Green
                  0xFF880E4F, // Dark Pink/Rose
                  0xFFE65100, // Dark Orange
                  0xFF263238, // Charcoal
                ];
                ctx.updateNodeStyle(nodeId, (style) {
                  final index = textColors.indexOf(style.textColor);
                  final nextColor = textColors[(index + 1) % textColors.length];
                  return style.copyWith(textColor: nextColor);
                });
              }
              return const CanvasIdle();
            } else {
              // Row 2 (Bottom): Existing controls (Drag Handle, Link/Relation, Save Template, Delete)
              final clickedButtonIndex = (localX / btnWidth).floor().clamp(0, 3);
              if (clickedButtonIndex == 0) {
                // Zone 1: Drag (toolbar repositioning)
                return ToolbarDragging(
                  selectedEntities.first,
                  pCanvas - toolbarTopLeft,
                );
              } else if (clickedButtonIndex == 1) {
                // Zone 2: Link (New Relation) - enters sticky RelationDrawing mode
                return RelationDrawing(selectedEntities, pCanvas, isSticky: true);
              } else if (clickedButtonIndex == 2) {
                // Zone 3: Save Template (bookmark_add)
                ctx.onSaveTemplate();
                return const CanvasIdle();
              } else {
                // Zone 4: Delete
                ctx.onDeleteSelectedEntities();
                return const CanvasIdle();
              }
            }
          } else {
            // Existing logic for multi-selection or relation-only toolbar
            final int numButtons = isRelationOnly
                ? 2
                : (canSaveTemplate ? 4 : 3);
            final double btnWidth = toolbarWidth / numButtons;
            final int clickedButtonIndex = (localX / btnWidth).floor().clamp(0, numButtons - 1);

            if (isRelationOnly) {
              // Relation toolbar: Zone 1 (Drag), Zone 2 (Delete) - Link is omitted
              if (clickedButtonIndex == 0) {
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
              // Node toolbar: 3-zone or 4-zone logic depending on canSaveTemplate
              if (clickedButtonIndex == 0) {
                // Zone 1: Drag (toolbar repositioning)
                return ToolbarDragging(
                  selectedEntities.first,
                  pCanvas - toolbarTopLeft,
                );
              } else if (clickedButtonIndex == 1) {
                // Zone 2: Link (New Relation) - enters sticky RelationDrawing mode
                return RelationDrawing(selectedEntities, pCanvas, isSticky: true);
              } else if (canSaveTemplate && clickedButtonIndex == 2) {
                // Zone 3: Save Template (bookmark_add)
                ctx.onSaveTemplate();
                return const CanvasIdle();
              } else {
                // Zone 4 (or 3 if no template): Delete
                ctx.onDeleteSelectedEntities();
                return const CanvasIdle();
              }
            }
          }
        }
      }
    }

    // Hit Testing Registry
    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    // Priority -0.2: Metadata Sphere Hit-Testing
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;
      final node = ctx.getNode(nodeId);
      if (node is InfoUiNode && (node.tags.isNotEmpty || node.comments.isNotEmpty)) {
        final nodeRect = vs.rect;
        final center = Offset(
          nodeRect.right - AppConfig.node.metadataSphereOffsetFromRight,
          nodeRect.top + AppConfig.node.metadataSphereOffsetFromTop,
        );
        if ((pCanvas - center).distance < AppConfig.node.metadataSphereHitboxRadius) {
          _canvasIdleLog.fine('Metadata sphere hit: $nodeId');
          ctx.openDataInspector(nodeId);
          return this;
        }
      }
    }

    String? hitNodeId;
    bool hitResize = false;
    ResizeEdge? draggedEdge;

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
    final hitEntityId = hitNodeId ?? _hitTestRelations(pCanvas, ctx, layoutContext);

    // Commit active edit if clicking elsewhere or if clicking a resize handle of the edited node
    if (activeEditId != null && (hitEntityId != activeEditId || hitResize)) {
      ctx.onCommitActiveEdit();
    }

    // Fire selection intent immediately on pointer down.
    // If hitEntityId is null (clicked empty canvas), it clears the selection.
    _canvasIdleLog.fine('Selection Intent: HitEntity=$hitEntityId'); // [NEW]
    if (hitEntityId == null || !selectedEntities.contains(hitEntityId)) {
      ctx.onSelectEntity(hitEntityId);
    }

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
        final nodeIdsInSelection = selectedEntities
            .where((id) => ctx.nodeViewStates.containsKey(id))
            .toList();
        if (nodeIdsInSelection.length > 1 && nodeIdsInSelection.contains(hitNodeId)) {
          final originalPositions = {
            for (final id in nodeIdsInSelection)
              id: ctx.nodeViewStates[id]!.positionNotifier.value
          };
          return GroupDragging(
            nodeIds: nodeIdsInSelection,
            anchorNodeId: hitNodeId,
            grabOffset: pCanvas - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value,
            originalPositions: originalPositions,
          );
        } else {
          return NodeDragging(
            hitNodeId,
            pCanvas - ctx.nodeViewStates[hitNodeId]!.positionNotifier.value,
          );
        }
      }
    }

    return this;
  }

  /// Hit-tests relation labels at the midpoint between connected nodes.
  String? _hitTestRelations(Offset p, InteractionContext ctx, RelationLayoutContext layoutContext) {
    for (final rel in ctx.getRelations()) {
      final fVs = ctx.nodeViewStates[rel.fromNodeId];
      final tVs = ctx.nodeViewStates[rel.toNodeId];
      if (fVs == null || tVs == null) continue;

      final layoutStrategy = RelationLayoutStrategy.fromType(rel.layout?.strategyType);
      final (start, end) = layoutStrategy.resolveEndpoints(rel, fVs, tVs);
      final mid = layoutStrategy.computeLabelPosition(start, end, fVs, tVs, rel, layoutContext);

      // Hit-test the label bounding box
      if (Rect.fromCenter(
        center: mid,
        width: AppConfig.interaction.relationLabelHitArea.width,
        height: AppConfig.interaction.relationLabelHitArea.height,
      ).contains(p)) {
        return rel.id;
      }

      // Hit-test the line/curve path (8px threshold)
      if (layoutStrategy.isPointNear(p, start, end, fVs, tVs, rel, 8.0, layoutContext)) {
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

      // Metadata sphere hover hit test
      final node = ctx.getNode(nodeId);
      if (node is InfoUiNode && (node.tags.isNotEmpty || node.comments.isNotEmpty)) {
        final nodeRect = vs.rect;
        final center = Offset(
          nodeRect.right - AppConfig.node.metadataSphereOffsetFromRight,
          nodeRect.top + AppConfig.node.metadataSphereOffsetFromTop,
        );
        if ((pCanvas - center).distance < AppConfig.node.metadataSphereHitboxRadius) {
          return cursor == SystemMouseCursors.click
              ? this
              : const CanvasIdle(cursor: SystemMouseCursors.click);
        }
      }

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
