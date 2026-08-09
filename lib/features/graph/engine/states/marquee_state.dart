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
  bool get allowsAutoPan => true;

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

    final Set<RawUuid> hits = {};

    for (final id in nodeIdsToCheck) {
      final vs = ctx.nodeViewStates[id];
      if (vs != null && vs.rect.overlaps(marqueeRect)) {
        hits.add(id);
      }
    }

    final cache = ctx.relationEngine.cache;
    for (final entry in cache.entries) {
      final computed = entry.value;
      final bbox = Rect.fromLTWH(
        computed.bbox.x,
        computed.bbox.y,
        computed.bbox.width,
        computed.bbox.height,
      );
      if (!bbox.overlaps(marqueeRect)) continue;
      if (_rectIntersectsMarquee(marqueeRect, computed.pathPoints)) {
        hits.add(entry.key);
      }
    }

    _marqueeLog.info(
      'Marquee Complete: Captured ${hits.length} entities in $marqueeRect',
    );
    ctx.onSelectEntities(hits);
    return const CanvasIdle();
  }

  static bool _rectIntersectsMarquee(Rect rect, List<rust_geo.Point> pathPoints) {
    if (pathPoints.length < 2) return false;
    for (var i = 0; i < pathPoints.length - 1; i++) {
      final a = Offset(pathPoints[i].x, pathPoints[i].y);
      final b = Offset(pathPoints[i + 1].x, pathPoints[i + 1].y);
      if (rect.contains(a) || rect.contains(b)) return true;
      if (_segmentIntersectsRect(a, b, rect)) return true;
    }
    return false;
  }

  static bool _segmentIntersectsRect(Offset a, Offset b, Rect rect) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;

    if (dx == 0 && dy == 0) return false;

    var tmin = 0.0;
    var tmax = 1.0;

    if (dx != 0) {
      final t1 = (rect.left - a.dx) / dx;
      final t2 = (rect.right - a.dx) / dx;
      final tNear = t1 < t2 ? t1 : t2;
      final tFar = t1 < t2 ? t2 : t1;
      if (tNear > tmin) tmin = tNear;
      if (tFar < tmax) tmax = tFar;
      if (tmin > tmax) return false;
    } else {
      if (a.dx < rect.left || a.dx > rect.right) return false;
    }

    if (dy != 0) {
      final t1 = (rect.top - a.dy) / dy;
      final t2 = (rect.bottom - a.dy) / dy;
      final tNear = t1 < t2 ? t1 : t2;
      final tFar = t1 < t2 ? t2 : t1;
      if (tNear > tmin) tmin = tNear;
      if (tFar < tmax) tmax = tFar;
      if (tmin > tmax) return false;
    } else {
      if (a.dy < rect.top || a.dy > rect.bottom) return false;
    }

    return tmin <= tmax;
  }
}
