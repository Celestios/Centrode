// lib/features/graph/state/states/toolbar_dragging.dart
part of '../base_interaction_state.dart';

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

    final selected = ctx.getSelectedEntities();
    final isMulti = selected.length > 1;

    if (isMulti) {
      // Calculate mathematically accurate Canvas Space Bounding Box
      double minX = double.infinity,
          minY = double.infinity,
          maxX = double.negativeInfinity,
          maxY = double.negativeInfinity;
      for (final id in selected) {
        final viewState = ctx.nodeViewStates[id];
        if (viewState == null) continue;
        final rect = viewState.rect;
        if (rect.left < minX) minX = rect.left;
        if (rect.top < minY) minY = rect.top;
        if (rect.right > maxX) maxX = rect.right;
        if (rect.bottom > maxY) maxY = rect.bottom;
      }

      if (minX != double.infinity) {
        // Center horizontally above the bounding box
        final centerX = minX + (maxX - minX) / 2;
        anchor = Offset(
          centerX - (AppConfig.toolbar.multiWidth / 2),
          minY - AppConfig.toolbar.height - 10,
        );
      }
    } else {
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

          final (start, end) = RelationLayoutStrategy.resolveEndpoints(rel, sourceVs, targetVs);
          anchor = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        } catch (_) {
          return const CanvasIdle();
        }
      }
    }

    // Calculate new absolute position of the toolbar
    final newAbsolutePos = pCanvas - grabOffset;

    // Calculate new relative offset from the entity's anchor position
    final newRelativeOffset = newAbsolutePos - anchor;

    ctx.setToolbarOffset(newRelativeOffset);
    return this;
  }
}
