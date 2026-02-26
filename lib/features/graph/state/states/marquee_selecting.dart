// lib/features/graph/state/states/marquee_selecting.dart
part of '../canvas_interaction_states.dart';

/// Logger for MarqueeSelecting state telemetry
final Logger _marqueeLog = Logger('MarqueeSelecting');

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

    _marqueeLog.finer(
      'Marquee Release: Evaluating bounds $marqueeRect against spatial index.',
    );

    var nodeIdsToCheck = ctx.getVisibleNodeIds();

    // Fallback for T=0 state where viewport hasn't triggered a spatial query yet
    if (nodeIdsToCheck.isEmpty) {
      // [NEW] Pitfall 4 Diagnostic - T=0 Fallback warning
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
