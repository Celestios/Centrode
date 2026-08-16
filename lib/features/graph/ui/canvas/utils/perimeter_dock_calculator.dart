import 'dart:ui';

/// Bidirectional line segment intersection with a Container Rect.
/// Correctly computes perimeter intersection regardless of whether ray moves from inside->outside or outside->inside.
Offset calculateContainerPerimeterDock(
  RRect containerRRect,
  Offset pStart,
  Offset pEnd,
) {
  final rect = containerRRect.outerRect;
  final dir = (pEnd - pStart);
  if (dir == Offset.zero) return rect.center;

  return _intersectSegmentBox(rect, pStart, pEnd);
}

Offset _intersectSegmentBox(Rect rect, Offset pStart, Offset pEnd) {
  final dir = pEnd - pStart;
  double tMin = 0.0;
  double tMax = 1.0;

  if (dir.dx != 0.0) {
    final tx1 = (rect.left - pStart.dx) / dir.dx;
    final tx2 = (rect.right - pStart.dx) / dir.dx;
    tMin = (tMin > (tx1 < tx2 ? tx1 : tx2)) ? tMin : (tx1 < tx2 ? tx1 : tx2);
    tMax = (tMax < (tx1 > tx2 ? tx1 : tx2)) ? tMax : (tx1 > tx2 ? tx1 : tx2);
  }
  if (dir.dy != 0.0) {
    final ty1 = (rect.top - pStart.dy) / dir.dy;
    final ty2 = (rect.bottom - pStart.dy) / dir.dy;
    tMin = (tMin > (ty1 < ty2 ? ty1 : ty2)) ? tMin : (ty1 < ty2 ? ty1 : ty2);
    tMax = (tMax < (ty1 > ty2 ? ty1 : ty2)) ? tMax : (ty1 > ty2 ? ty1 : ty2);
  }

  if (tMin > tMax) return pEnd;

  final bool isStartInside = rect.contains(pStart);
  final double tBoundary = isStartInside ? tMax : tMin;

  final clampedT = tBoundary.clamp(0.0, 1.0);
  return pStart + (dir * clampedT);
}
