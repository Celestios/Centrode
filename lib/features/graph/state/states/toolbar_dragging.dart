// lib/features/graph/state/states/toolbar_dragging.dart
part of '../canvas_interaction_states.dart';

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
    InteractionContext ctx,
  ) {
    Offset anchor = Offset.zero;

    // Check if it's a node or a relation
    final vs = ctx.nodeViewStates[entityId];

    if (vs != null) {
      // Node entity: use node position as anchor
      anchor = vs.positionNotifier.value;
    } else {
      // Relation entity: calculate dynamic midpoint anchor
      try {
        final rel = ctx.getRelations().firstWhere((r) => r.id == entityId);
        final sourceVs = ctx.nodeViewStates[rel.fromNodeId];
        final targetVs = ctx.nodeViewStates[rel.toNodeId];
        if (sourceVs == null || targetVs == null) return const CanvasIdle();

        final start = sourceVs.rightPort;
        final end = targetVs.leftPort;
        anchor = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      } catch (_) {
        return const CanvasIdle();
      }
    }

    // Calculate new absolute position of the toolbar
    final newAbsolutePos = pCanvas - grabOffset;

    // Calculate new relative offset from the entity's anchor position
    final newRelativeOffset = newAbsolutePos - anchor;

    ctx.updateToolbarOffset(newRelativeOffset);
    return this;
  }
}
