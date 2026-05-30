// lib/features/graph/state/states/marquee_selecting.dart
part of '../base_interaction_state.dart';

/// Logger for MarqueeSelecting state telemetry
final Logger _marqueeLog = Logger('MarqueeSelecting');

/// State when dragging a marquee selection box via left-click on empty space.
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

    _marqueeLog.finer(
      'Marquee Release: Evaluating bounds $marqueeRect against spatial index.',
    );

    var nodeIdsToCheck = ctx.getVisibleNodeIds();

    if (nodeIdsToCheck.isEmpty) {
      _marqueeLog.warning(
        'Marquee T=0 Fallback: Spatial index empty, querying all ${ctx.nodeViewStates.length} ViewStates.',
      );
      nodeIdsToCheck = ctx.nodeViewStates.keys.toSet();
    }

    final Set<String> hits = {};

    for (final id in nodeIdsToCheck) {
      final vs = ctx.nodeViewStates[id];
      if (vs != null && vs.rect.overlaps(marqueeRect)) {
        hits.add(id);
      }
    }

    _marqueeLog.info(
      'Marquee Complete: Captured ${hits.length} entities in $marqueeRect',
    ); // [NEW]
    ctx.onSelectEntities(hits);
    return const CanvasIdle();
  }
}
