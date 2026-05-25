import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

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
  );

  /// Resolves positions for the tip handles, placed slightly before the start and end tips.
  (Offset, Offset) resolveTipHandles(
    UiRelation relation,
    NodeViewState fromVs,
    NodeViewState toVs, {
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
    final dir = len == 0.0 ? Offset.zero : (end - start) / len;
    return (
      start + dir * 16.0,
      end - dir * 16.0,
    );
  }

  /// Computes the center position where the relation label should be rendered.
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
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
  ) {
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }

  @override
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
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
  ) {
    return distanceToSegment(p, start, end) <= threshold;
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

  (Offset, Offset) _getBezierControlPoints(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    final layout = relation.resolvedLayout ?? relation.layout;
    final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
    final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

    final startNormal = _getPortNormal(fromSide, start, end);
    final endNormal = _getPortNormal(toSide, end, start);

    final distance = (end - start).distance;
    final proj = (distance * 0.4).clamp(30.0, 150.0);
    final p1 = start + startNormal * proj;
    final p2 = end + endNormal * proj;
    return (p1, p2);
  }

  @override
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    final distance = (end - start).distance;
    if (distance < 1.0) {
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
    }

    final (p1, p2) = _getBezierControlPoints(start, end, fromVs, toVs, relation);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, end.dx, end.dy);
  }

  @override
  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    final distance = (end - start).distance;
    if (distance < 1.0) {
      return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    }

    final (p1, p2) = _getBezierControlPoints(start, end, fromVs, toVs, relation);

    // Cubic Bezier evaluation at t = 0.5
    // B(0.5) = 0.125 * start + 0.375 * p1 + 0.375 * p2 + 0.125 * end
    return start * 0.125 + p1 * 0.375 + p2 * 0.375 + end * 0.125;
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
  ) {
    final distance = (end - start).distance;
    if (distance < 1.0) {
      return (p - start).distance <= threshold;
    }

    final (p1, p2) = _getBezierControlPoints(start, end, fromVs, toVs, relation);

    // Sample 10 linear segments along the curve
    Offset prev = start;
    for (int i = 1; i <= 10; i++) {
      final t = i / 10.0;
      final mt = 1.0 - t;
      final next = start * (mt * mt * mt) +
          p1 * (3 * mt * mt * t) +
          p2 * (3 * mt * t * t) +
          end * (t * t * t);

      if (distanceToSegment(p, prev, next) <= threshold) {
        return true;
      }
      prev = next;
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

  String _resolveSideFromOffset(NodeViewState vs, Offset offset, String? side) {
    if (side != null && side != 'Auto') {
      return side;
    }
    final closest = vs.getClosestPort(offset);
    if ((closest.position - offset).distance < 5.0) {
      return closest.name;
    }
    return 'Auto';
  }

  Offset _getCardinalNormal(String side, Offset start, Offset end) {
    switch (side) {
      case 'Left':
      case 'TopLeft':
      case 'BottomLeft':
        return const Offset(-1.0, 0.0);
      case 'Right':
      case 'TopRight':
      case 'BottomRight':
        return const Offset(1.0, 0.0);
      case 'Top':
        return const Offset(0.0, -1.0);
      case 'Bottom':
        return const Offset(0.0, 1.0);
      default:
        final dir = end - start;
        if (dir.dx.abs() > dir.dy.abs()) {
          return Offset(dir.dx.sign, 0.0);
        } else {
          return Offset(0.0, dir.dy.sign);
        }
    }
  }

  List<Offset> _getOrthogonalPoints(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    if ((end - start).distance < 25.0) {
      return [start, end];
    }

    final layout = relation.resolvedLayout ?? relation.layout;
    final startSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
    final endSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

    final nStart = _getCardinalNormal(startSide, start, end);
    final nEnd = _getCardinalNormal(endSide, end, start);

    const gap = 20.0;
    final pStart = start + nStart * gap;
    final pEnd = end + nEnd * gap;

    final List<Offset> points = [start, pStart];

    final isStartHorizontal = nStart.dx.abs() > 0.5;
    final isEndHorizontal = nEnd.dx.abs() > 0.5;

    if (isStartHorizontal && isEndHorizontal) {
      final midX = (pStart.dx + pEnd.dx) / 2;
      points.add(Offset(midX, pStart.dy));
      points.add(Offset(midX, pEnd.dy));
    } else if (!isStartHorizontal && !isEndHorizontal) {
      final midY = (pStart.dy + pEnd.dy) / 2;
      points.add(Offset(pStart.dx, midY));
      points.add(Offset(pEnd.dx, midY));
    } else if (isStartHorizontal && !isEndHorizontal) {
      points.add(Offset(pEnd.dx, pStart.dy));
    } else {
      points.add(Offset(pStart.dx, pEnd.dy));
    }

    points.add(pEnd);
    points.add(end);

    final List<Offset> cleanPoints = [];
    for (final p in points) {
      if (cleanPoints.isEmpty || (cleanPoints.last - p).distance > 0.1) {
        cleanPoints.add(p);
      }
    }
    return cleanPoints;
  }

  @override
  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
  ) {
    final points = _getOrthogonalPoints(start, end, fromVs, toVs, relation);
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
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
  ) {
    final points = _getOrthogonalPoints(start, end, fromVs, toVs, relation);
    if (points.length < 2) return (start + end) / 2;

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final len = (points[i+1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return points.first;

    final targetLength = totalLength * 0.5;
    double currentLength = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      final len = segmentLengths[i];
      if (currentLength + len >= targetLength) {
        final t = (targetLength - currentLength) / len;
        return Offset.lerp(points[i], points[i+1], t)!;
      }
      currentLength += len;
    }
    return points.last;
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
  ) {
    final points = _getOrthogonalPoints(start, end, fromVs, toVs, relation);
    if (points.length < 2) {
      return distanceToSegment(p, start, end) <= threshold;
    }
    for (int i = 0; i < points.length - 1; i++) {
      if (distanceToSegment(p, points[i], points[i+1]) <= threshold) {
        return true;
      }
    }
    return false;
  }
}
