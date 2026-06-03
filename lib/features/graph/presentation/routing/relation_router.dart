import 'dart:math';
import 'package:flutter/painting.dart';

/// Geometric router that calculates detours around node obstacles.
class RelationRouter {
  /// Computes a list of waypoints from [start] to [end] avoiding [obstacles].
  static List<Offset> computeWaypoints({
    required Offset start,
    required Offset end,
    required List<Rect> obstacles,
    double margin = 45.0,
    int maxDepth = 3,
  }) {
    final path = _route(start, end, obstacles, margin, 0, maxDepth);
    final simplified = _simplifyPath(path, obstacles);
    
    final cleanPath = <Offset>[];
    for (final p in simplified) {
      if (cleanPath.isEmpty || (cleanPath.last - p).distance > 0.01) {
        cleanPath.add(p);
      }
    }
    return cleanPath;
  }

  /// Pulls shortcuts along the path to remove redundant detour waypoints.
  static List<Offset> _simplifyPath(List<Offset> path, List<Rect> obstacles) {
    if (path.length < 3) return path;

    final List<Offset> simplified = [path.first];
    int current = 0;

    while (current < path.length - 1) {
      int furthest = current + 1;
      for (int candidate = path.length - 1; candidate > current + 1; candidate--) {
        bool intersects = false;
        for (final rect in obstacles) {
          if (segmentIntersectsRect(path[current], path[candidate], rect)) {
            intersects = true;
            break;
          }
        }
        if (!intersects) {
          furthest = candidate;
          break;
        }
      }
      simplified.add(path[furthest]);
      current = furthest;
    }
    return simplified;
  }

  static List<Offset> _route(
    Offset a,
    Offset b,
    List<Rect> obstacles,
    double margin,
    int depth,
    int maxDepth,
  ) {
    if (depth >= maxDepth) {
      return [a, b];
    }

    Rect? targetRect;
    double minDistance = double.infinity;

    // Find the closest obstacle that intersects the direct line from a to b
    for (final rect in obstacles) {
      if (segmentIntersectsRect(a, b, rect)) {
        final dist = (rect.center - a).distance;
        if (dist < minDistance) {
          minDistance = dist;
          targetRect = rect;
        }
      }
    }

    if (targetRect == null) {
      return [a, b];
    }

    // Pad the corners of the targetRect outwards by [margin]
    final double left = targetRect.left - margin;
    final double right = targetRect.right + margin;
    final double top = targetRect.top - margin;
    final double bottom = targetRect.bottom + margin;

    final pTL = Offset(left, top);
    final pTR = Offset(right, top);
    final pBL = Offset(left, bottom);
    final pBR = Offset(right, bottom);

    // Candidates for bypass paths:
    // 1. Go above (top-left to top-right)
    // 2. Go below (bottom-left to bottom-right)
    // 3. Go left (top-left to bottom-left)
    // 4. Go right (top-right to bottom-right)
    final candidates = <List<Offset>>[
      [pTL, pTR],
      [pBL, pBR],
      [pTL, pBL],
      [pTR, pBR],
    ];

    List<Offset>? bestRoute;
    double bestLength = double.infinity;
    int minIntersectionsCount = 9999;

    // First try: strictly avoid routing detours into other obstacles
    for (final cand in candidates) {
      bool candInsideObstacle = false;
      for (final r in obstacles) {
        if (r != targetRect && (r.contains(cand[0]) || r.contains(cand[1]))) {
          candInsideObstacle = true;
          break;
        }
      }
      if (candInsideObstacle) continue;

      final segment1 = _route(a, cand[0], obstacles, margin, depth + 1, maxDepth);
      final segment2 = _route(cand[0], cand[1], obstacles, margin, depth + 1, maxDepth);
      final segment3 = _route(cand[1], b, obstacles, margin, depth + 1, maxDepth);

      final merged = <Offset>[];
      merged.addAll(segment1);
      for (final p in segment2) {
        if (merged.isEmpty || (merged.last - p).distance > 0.01) merged.add(p);
      }
      for (final p in segment3) {
        if (merged.isEmpty || (merged.last - p).distance > 0.01) merged.add(p);
      }

      double length = 0.0;
      for (int i = 0; i < merged.length - 1; i++) {
        length += (merged[i + 1] - merged[i]).distance;
      }

      int intersectionsCount = 0;
      for (int i = 0; i < merged.length - 1; i++) {
        for (final r in obstacles) {
          if (segmentIntersectsRect(merged[i], merged[i + 1], r)) {
            intersectionsCount++;
          }
        }
      }

      if (intersectionsCount < minIntersectionsCount ||
          (intersectionsCount == minIntersectionsCount && length < bestLength)) {
        minIntersectionsCount = intersectionsCount;
        bestLength = length;
        bestRoute = merged;
      }
    }

    // Fallback: If all candidates are inside other obstacles (dense cluster), relax candidate check
    if (bestRoute == null) {
      for (final cand in candidates) {
        final segment1 = _route(a, cand[0], obstacles, margin, depth + 1, maxDepth);
        final segment2 = _route(cand[0], cand[1], obstacles, margin, depth + 1, maxDepth);
        final segment3 = _route(cand[1], b, obstacles, margin, depth + 1, maxDepth);

        final merged = <Offset>[];
        merged.addAll(segment1);
        for (final p in segment2) {
          if (merged.isEmpty || (merged.last - p).distance > 0.01) merged.add(p);
        }
        for (final p in segment3) {
          if (merged.isEmpty || (merged.last - p).distance > 0.01) merged.add(p);
        }

        double length = 0.0;
        for (int i = 0; i < merged.length - 1; i++) {
          length += (merged[i + 1] - merged[i]).distance;
        }

        int intersectionsCount = 0;
        for (int i = 0; i < merged.length - 1; i++) {
          for (final r in obstacles) {
            if (segmentIntersectsRect(merged[i], merged[i + 1], r)) {
              intersectionsCount++;
            }
          }
        }

        if (intersectionsCount < minIntersectionsCount ||
            (intersectionsCount == minIntersectionsCount && length < bestLength)) {
          minIntersectionsCount = intersectionsCount;
          bestLength = length;
          bestRoute = merged;
        }
      }
    }

    return bestRoute ?? [a, b];
  }

  /// Checks if the segment [p1]-[p2] intersects the rectangle [rect].
  static bool segmentIntersectsRect(Offset p1, Offset p2, Rect rect) {
    if (rect.contains(p1) || rect.contains(p2)) return true;

    final rTL = rect.topLeft;
    final rTR = rect.topRight;
    final rBL = rect.bottomLeft;
    final rBR = rect.bottomRight;

    return _segmentsIntersect(p1, p2, rTL, rTR) ||
           _segmentsIntersect(p1, p2, rTR, rBR) ||
           _segmentsIntersect(p1, p2, rBR, rBL) ||
           _segmentsIntersect(p1, p2, rBL, rTL);
  }

  /// Checks if segment [a]-[b] intersects segment [c]-[d] using orientation checks.
  static bool _segmentsIntersect(Offset a, Offset b, Offset c, Offset d) {
    double ccw(Offset p1, Offset p2, Offset p3) {
      return (p3.dy - p1.dy) * (p2.dx - p1.dx) - (p2.dy - p1.dy) * (p3.dx - p1.dx);
    }

    final val1 = ccw(a, b, c);
    final val2 = ccw(a, b, d);
    final val3 = ccw(c, d, a);
    final val4 = ccw(c, d, b);

    // General case: lines cross
    if (((val1 > 0 && val2 < 0) || (val1 < 0 && val2 > 0)) &&
        ((val3 > 0 && val4 < 0) || (val3 < 0 && val4 > 0))) {
      return true;
    }

    // Special cases: collinear touching segments
    bool onSegment(Offset p, Offset q, Offset r) {
      return q.dx <= max(p.dx, r.dx) && q.dx >= min(p.dx, r.dx) &&
             q.dy <= max(p.dy, r.dy) && q.dy >= min(p.dy, r.dy);
    }

    if (val1 == 0 && onSegment(a, c, b)) return true;
    if (val2 == 0 && onSegment(a, d, b)) return true;
    if (val3 == 0 && onSegment(c, a, d)) return true;
    if (val4 == 0 && onSegment(c, b, d)) return true;

    return false;
  }
}
