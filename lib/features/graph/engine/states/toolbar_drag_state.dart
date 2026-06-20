// lib/features/graph/state/states/toolbar_dragging.dart
part of '../base_interaction_state.dart';

final Logger _toolbarDragLog = Logger('ToolbarDragging');

/// [NEW] State when dragging the floating toolbar to adjust its relative offset.
/// Supports both node entities and relation entities.
class ToolbarDragging extends CanvasInteractionState {
  final String entityId;
  final Offset grabOffset; // Pointer offset relative to the toolbar's top-left

  const ToolbarDragging(this.entityId, this.grabOffset);

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    SelectionCapability ctx,
  ) {
    _toolbarDragLog.fine('handlePointerMove entityId=$entityId');
    final selected = ctx.getSelectedEntities();
    if (selected.isEmpty) return const CanvasIdle();
    final anchor = ctx.calculateToolbarAnchor(selected);
    if (anchor == null) return const CanvasIdle();

    // Calculate new absolute position of the toolbar
    final newAbsolutePos = pCanvas - grabOffset;

    // Calculate new relative offset from the entity's anchor position
    final newRelativeOffset = newAbsolutePos - anchor;

    ctx.setToolbarOffset(newRelativeOffset);
    return this;
  }
}
