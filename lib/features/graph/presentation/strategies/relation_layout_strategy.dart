import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'routing/relation_layout_context.dart';
import 'routing/relation_router.dart';

/// Responsible for computing the physical size, bounds, or layout positions for a relation.
abstract class RelationLayoutStrategy {
  const RelationLayoutStrategy();

  /// Resolves the correct strategy based on type.
  static RelationLayoutStrategy fromType(String? type) {
    if (type == 'bezier') {
      return const BezierRelationLayoutStrategy();
    }
    if (type == 'orthogonal') {
      return const OrthogonalRelationLayoutStrategy();
    }
    return const StraightRelationLayoutStrategy();
  }

  /// Calculates the size of the relation elements (e.g., label bounding box).
  Size calculate(UiRelation relation, RelationStyle style);

  /// Resolves the start and end offsets for drawing this relation,
  /// using either the persisted layout sides, dynamic calculations, or drag overrides.
  (Offset start, Offset end) resolveEndpoints(
    UiRelation relation,
    NodeViewState fromVs,
    NodeViewState toVs, {
    Offset? overrideStart,
    Offset? overrideEnd,
  }) {
    final layout = relation.resolvedLayout ?? relation.layout;
    final fromSide = layout?.fromSide;
    final toSide = layout?.toSide;

    final startSize = fromVs.sizeNotifier.value;
    final endSize = toVs.sizeNotifier.value;

    Offset start;
    Offset end;

    if (overrideStart != null) {
      start = overrideStart;
    } else if (startSize == Size.zero) {
      start = fromVs.positionNotifier.value + AppConfig.relation.startFallback;
    } else if (fromSide != null && fromSide != 'Auto') {
      start = fromVs.getPortPosition(fromSide);
    } else {
      start = fromVs.rightPort;
    }

    if (overrideEnd != null) {
      end = overrideEnd;
    } else if (endSize == Size.zero) {
      end = toVs.positionNotifier.value + AppConfig.relation.endFallback;
    } else if (toSide != null && toSide != 'Auto') {
      end = toVs.getPortPosition(toSide);
    } else {
      end = toVs.leftPort;
    }

    // 1. Dragging start tip: resolve end port dynamically relative to active start if end side is Auto
    if (overrideStart != null && overrideEnd == null && endSize != Size.zero && (toSide == null || toSide == 'Auto')) {
      end = toVs.getClosestPort(overrideStart).position;
    }
    // 2. Dragging end tip: resolve start port dynamically relative to active end if start side is Auto
    else if (overrideEnd != null && overrideStart == null && startSize != Size.zero && (fromSide == null || fromSide == 'Auto')) {
      start = fromVs.getClosestPort(overrideEnd).position;
    }
    // 3. Normal routing (neither side is overridden)
    else if (overrideStart == null && overrideEnd == null && startSize != Size.zero && endSize != Size.zero &&
        ((fromSide == null || fromSide == 'Auto') || (toSide == null || toSide == 'Auto'))) {
      if (fromSide != null && fromSide != 'Auto') {
        final explicitStart = fromVs.getPortPosition(fromSide);
        start = explicitStart;
        end = toVs.getClosestPort(explicitStart).position;
      } else if (toSide != null && toSide != 'Auto') {
        final explicitEnd = toVs.getPortPosition(toSide);
        start = fromVs.getClosestPort(explicitEnd).position;
        end = explicitEnd;
      } else {
        final closest = NodeViewState.getClosestPortsBetween(fromVs, toVs);
        start = closest.startPos;
        end = closest.endPos;
      }
    }

    return (start, end);
  }

  /// Computes the Path for drawing this relation.
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  );

  /// Resolves positions for the tip handles, placed slightly before the start and end tips.
  (Offset, Offset) resolveTipHandles(
    UiRelation relation,
    NodeViewState fromVs,
    NodeViewState toVs,
    RelationLayoutContext context, {
    Offset? overrideStart,
    Offset? overrideEnd,
  }) {
    final (start, end) = resolveEndpoints(
      relation,
      fromVs,
      toVs,
      overrideStart: overrideStart,
      overrideEnd: overrideEnd,
    );

    final len = (end - start).distance;
    if (len < 40.0) {
      return (
        start + (end - start) * (1 / 3),
        start + (end - start) * (2 / 3),
      );
    }

    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    if (waypoints.length < 2) {
      return (start, end);
    }

    // Start handle: 16px along the waypoints path from start
    Offset hStart = start;
    double distLeft = 16.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = waypoints[i];
      final p2 = waypoints[i + 1];
      final segLen = (p2 - p1).distance;
      if (segLen >= distLeft) {
        final dir = segLen == 0.0 ? Offset.zero : (p2 - p1) / segLen;
        hStart = p1 + dir * distLeft;
        break;
      } else {
        distLeft -= segLen;
      }
    }

    // End handle: 16px back along the waypoints path from end
    Offset hEnd = end;
    distLeft = 16.0;
    for (int i = waypoints.length - 1; i > 0; i--) {
      final p2 = waypoints[i];
      final p1 = waypoints[i - 1];
      final segLen = (p2 - p1).distance;
      if (segLen >= distLeft) {
        final dir = segLen == 0.0 ? Offset.zero : (p2 - p1) / segLen;
        hEnd = p2 - dir * distLeft;
        break;
      } else {
        distLeft -= segLen;
      }
    }

    return (hStart, hEnd);
  }

  /// Computes the center position where the relation label should be rendered.
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  );

  /// Checks if a point is near the relation line/curve.
  bool isPointNear(
    Offset p,
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    double threshold,
    RelationLayoutContext context,
  );

  /// Helper to calculate the shortest distance from a point to a line segment.
  double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0.0) return ap.distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lenSq).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).distance;
  }

  /// Helper to query, compute, and cache obstacle-avoiding waypoints.
  List<Offset> getWaypoints(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final cached = context.pathCache[relation.id];
    if (cached != null) return cached;

    final obstacles = context.getObstacles(
      excludeFromId: relation.fromNodeId,
      excludeToId: relation.toNodeId,
    );

    final waypoints = RelationRouter.computeWaypoints(
      start: start,
      end: end,
      obstacles: obstacles,
    );

    context.pathCache[relation.id] = waypoints;
    return waypoints;
  }
}

class StraightRelationLayoutStrategy extends RelationLayoutStrategy {
  const StraightRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return AppConfig.interaction.relationLabelHitArea;
  }

  @override
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    final path = Path();
    if (waypoints.isNotEmpty) {
      path.moveTo(waypoints.first.dx, waypoints.first.dy);
      for (int i = 1; i < waypoints.length; i++) {
        path.lineTo(waypoints[i].dx, waypoints[i].dy);
      }
    }
    return path;
  }

  @override
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    if (waypoints.length < 2) return (start + end) / 2;

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final len = (waypoints[i + 1] - waypoints[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return waypoints.first;

    final targetLength = totalLength * 0.5;
    double currentLength = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      final len = segmentLengths[i];
      if (currentLength + len >= targetLength) {
        final t = (targetLength - currentLength) / len;
        return Offset.lerp(waypoints[i], waypoints[i + 1], t)!;
      }
      currentLength += len;
    }
    return waypoints.last;
  }

  @override
  bool isPointNear(
    Offset p,
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    double threshold,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    if (waypoints.length < 2) {
      return distanceToSegment(p, start, end) <= threshold;
    }
    for (int i = 0; i < waypoints.length - 1; i++) {
      if (distanceToSegment(p, waypoints[i], waypoints[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }
}

class BezierRelationLayoutStrategy extends RelationLayoutStrategy {
  const BezierRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return AppConfig.interaction.relationLabelHitArea;
  }

  Offset _getPortNormal(String? side, Offset start, Offset end) {
    if (side == null || side == 'Auto') {
      final dir = end - start;
      if (dir.distance < 1.0) return const Offset(1, 0);
      return dir / dir.distance;
    }
    switch (side) {
      case 'Left':
        return const Offset(-1, 0);
      case 'Right':
        return const Offset(1, 0);
      case 'Top':
        return const Offset(0, -1);
      case 'Bottom':
        return const Offset(0, 1);
      case 'TopLeft':
        return const Offset(-0.707, -0.707);
      case 'TopRight':
        return const Offset(0.707, -0.707);
      case 'BottomLeft':
        return const Offset(-0.707, 0.707);
      case 'BottomRight':
        return const Offset(0.707, 0.707);
      default:
        return const Offset(1, 0);
    }
  }

  String _resolveSideFromOffset(NodeViewState vs, Offset offset, String? side) {
    if (side != null && side != 'Auto') {
      return side;
    }
    final closest = vs.getClosestPort(offset);
    if ((closest.position - offset).distance < 2.0) {
      return closest.name;
    }
    return 'Auto';
  }

  Path _getBezierPath(
    List<Offset> waypoints,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    final path = Path();
    if (waypoints.isEmpty) return path;

    if (waypoints.length < 3) {
      // Standard single Bezier curve when unobstructed
      final start = waypoints.first;
      final end = waypoints.last;
      final layout = relation.resolvedLayout ?? relation.layout;
      final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
      final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

      final startNormal = _getPortNormal(fromSide, start, end);
      final endNormal = _getPortNormal(toSide, end, start);

      final distance = (end - start).distance;
      final proj = (distance * 0.4).clamp(30.0, 150.0);
      final p1 = start + startNormal * proj;
      final p2 = end + endNormal * proj;

      path.moveTo(start.dx, start.dy);
      path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, end.dx, end.dy);
      return path;
    }

    // Obstacle avoidance Bezier curve routing:
    // We construct a smooth rounded path through all waypoints.
    final start = waypoints.first;
    final end = waypoints.last;
    final layout = relation.resolvedLayout ?? relation.layout;
    final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
    final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

    final startNormal = _getPortNormal(fromSide, start, waypoints[1]);
    final endNormal = _getPortNormal(toSide, end, waypoints[waypoints.length - 2]);

    final points = <Offset>[];
    // Virtual start point to force orthogonal exit
    points.add(start - startNormal * 30.0);
    points.addAll(waypoints);
    // Virtual end point to force orthogonal entry
    points.add(end - endNormal * 30.0);

    final radius = 40.0;
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final pNext = points[i + 1];

      final d1 = (pCurr - pPrev).distance;
      final d2 = (pNext - pCurr).distance;
      final r = min(radius, min(d1 / 2, d2 / 2));

      final dir1 = d1 == 0.0 ? Offset.zero : (pCurr - pPrev) / d1;
      final dir2 = d2 == 0.0 ? Offset.zero : (pNext - pCurr) / d2;

      final startPoint = pCurr - dir1 * r;
      final endPoint = pCurr + dir2 * r;

      path.lineTo(startPoint.dx, startPoint.dy);
      path.quadraticBezierTo(pCurr.dx, pCurr.dy, endPoint.dx, endPoint.dy);
    }
    path.lineTo(end.dx, end.dy);

    return path;
  }

  List<Offset> _getBezierSamplePoints(
    List<Offset> waypoints,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    if (waypoints.isEmpty) return [];

    if (waypoints.length < 3) {
      final start = waypoints.first;
      final end = waypoints.last;
      final layout = relation.resolvedLayout ?? relation.layout;
      final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
      final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

      final startNormal = _getPortNormal(fromSide, start, end);
      final endNormal = _getPortNormal(toSide, end, start);

      final distance = (end - start).distance;
      final proj = (distance * 0.4).clamp(30.0, 150.0);
      final p1 = start + startNormal * proj;
      final p2 = end + endNormal * proj;

      final samples = <Offset>[];
      for (int i = 0; i <= 10; i++) {
        final t = i / 10.0;
        final mt = 1.0 - t;
        final pt = start * (mt * mt * mt) +
            p1 * (3 * mt * mt * t) +
            p2 * (3 * mt * t * t) +
            end * (t * t * t);
        samples.add(pt);
      }
      return samples;
    }

    final start = waypoints.first;
    final end = waypoints.last;
    final layout = relation.resolvedLayout ?? relation.layout;
    final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
    final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

    final startNormal = _getPortNormal(fromSide, start, waypoints[1]);
    final endNormal = _getPortNormal(toSide, end, waypoints[waypoints.length - 2]);

    final points = <Offset>[];
    points.add(start - startNormal * 30.0);
    points.addAll(waypoints);
    points.add(end - endNormal * 30.0);

    final samples = <Offset>[start];
    final radius = 40.0;

    for (int i = 1; i < points.length - 1; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final pNext = points[i + 1];

      final d1 = (pCurr - pPrev).distance;
      final d2 = (pNext - pCurr).distance;
      final r = min(radius, min(d1 / 2, d2 / 2));

      final dir1 = d1 == 0.0 ? Offset.zero : (pCurr - pPrev) / d1;
      final dir2 = d2 == 0.0 ? Offset.zero : (pNext - pCurr) / d2;

      final startPoint = pCurr - dir1 * r;
      final endPoint = pCurr + dir2 * r;

      samples.add(startPoint);
      for (int k = 1; k <= 3; k++) {
        final t = k / 3.0;
        final mt = 1.0 - t;
        final pt = startPoint * (mt * mt) + pCurr * (2 * mt * t) + endPoint * (t * t);
        samples.add(pt);
      }
    }
    samples.add(end);

    return samples;
  }

  @override
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    return _getBezierPath(waypoints, fromVs, toVs, relation);
  }

  @override
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    final samples = _getBezierSamplePoints(waypoints, fromVs, toVs, relation);
    if (samples.length < 2) return (start + end) / 2;

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < samples.length - 1; i++) {
      final len = (samples[i + 1] - samples[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return samples.first;

    final targetLength = totalLength * 0.5;
    double currentLength = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      final len = segmentLengths[i];
      if (currentLength + len >= targetLength) {
        final t = (targetLength - currentLength) / len;
        return Offset.lerp(samples[i], samples[i + 1], t)!;
      }
      currentLength += len;
    }
    return samples.last;
  }

  @override
  bool isPointNear(
    Offset p,
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    double threshold,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    final samples = _getBezierSamplePoints(waypoints, fromVs, toVs, relation);
    if (samples.length < 2) {
      return (p - start).distance <= threshold;
    }
    for (int i = 0; i < samples.length - 1; i++) {
      if (distanceToSegment(p, samples[i], samples[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }
}

class OrthogonalRelationLayoutStrategy extends RelationLayoutStrategy {
  const OrthogonalRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return AppConfig.interaction.relationLabelHitArea;
  }

  List<Offset> _getOrthogonalWaypoints(
    List<Offset> routed,
    List<Rect> obstacles,
  ) {
    if (routed.length < 2) return routed;
    final List<Offset> points = [routed.first];

    for (int i = 0; i < routed.length - 1; i++) {
      final p1 = points.last;
      final p2 = routed[i + 1];

      if ((p1.dx - p2.dx).abs() < 0.1 || (p1.dy - p2.dy).abs() < 0.1) {
        points.add(p2);
        continue;
      }

      final corner1 = Offset(p2.dx, p1.dy); // Horizontal first
      final corner2 = Offset(p1.dx, p2.dy); // Vertical first

      bool intersects1 = false;
      for (final rect in obstacles) {
        if (RelationRouter.segmentIntersectsRect(p1, corner1, rect) ||
            RelationRouter.segmentIntersectsRect(corner1, p2, rect)) {
          intersects1 = true;
          break;
        }
      }

      bool intersects2 = false;
      for (final rect in obstacles) {
        if (RelationRouter.segmentIntersectsRect(p1, corner2, rect) ||
            RelationRouter.segmentIntersectsRect(corner2, p2, rect)) {
          intersects2 = true;
          break;
        }
      }

      if (!intersects1 && intersects2) {
        points.add(corner1);
      } else if (intersects1 && !intersects2) {
        points.add(corner2);
      } else {
        points.add(corner1); // Default to horizontal-first
      }
      points.add(p2);
    }

    final clean = <Offset>[];
    for (final p in points) {
      if (clean.isEmpty || (clean.last - p).distance > 0.1) {
        clean.add(p);
      }
    }
    return clean;
  }

  List<Offset> getOrthoPoints(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final waypoints = getWaypoints(start, end, fromVs, toVs, relation, context);
    final obstacles = context.getObstacles(
      excludeFromId: relation.fromNodeId,
      excludeToId: relation.toNodeId,
    );
    return _getOrthogonalWaypoints(waypoints, obstacles);
  }

  @override
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final orthoPoints = getOrthoPoints(start, end, fromVs, toVs, relation, context);
    final path = Path();
    if (orthoPoints.isNotEmpty) {
      path.moveTo(orthoPoints.first.dx, orthoPoints.first.dy);
      for (int i = 1; i < orthoPoints.length; i++) {
        path.lineTo(orthoPoints[i].dx, orthoPoints[i].dy);
      }
    }
    return path;
  }

  @override
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  ) {
    final orthoPoints = getOrthoPoints(start, end, fromVs, toVs, relation, context);
    if (orthoPoints.length < 2) return (start + end) / 2;

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < orthoPoints.length - 1; i++) {
      final len = (orthoPoints[i + 1] - orthoPoints[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return orthoPoints.first;

    final targetLength = totalLength * 0.5;
    double currentLength = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      final len = segmentLengths[i];
      if (currentLength + len >= targetLength) {
        final t = (targetLength - currentLength) / len;
        return Offset.lerp(orthoPoints[i], orthoPoints[i + 1], t)!;
      }
      currentLength += len;
    }
    return orthoPoints.last;
  }

  @override
  bool isPointNear(
    Offset p,
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    double threshold,
    RelationLayoutContext context,
  ) {
    final orthoPoints = getOrthoPoints(start, end, fromVs, toVs, relation, context);
    if (orthoPoints.length < 2) {
      return distanceToSegment(p, start, end) <= threshold;
    }
    for (int i = 0; i < orthoPoints.length - 1; i++) {
      if (distanceToSegment(p, orthoPoints[i], orthoPoints[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }
}
