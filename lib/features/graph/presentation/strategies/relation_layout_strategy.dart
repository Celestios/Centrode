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
      double bestDist = double.infinity;
      Offset bestEnd = toVs.leftPort;
      for (final name in NodeViewState.portNames) {
        final portPos = toVs.getPortPosition(name);
        final dist = (overrideStart - portPos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestEnd = portPos;
        }
      }
      end = bestEnd;
    }
    // 2. Dragging end tip: resolve start port dynamically relative to active end if start side is Auto
    else if (overrideEnd != null && overrideStart == null && startSize != Size.zero && (fromSide == null || fromSide == 'Auto')) {
      double bestDist = double.infinity;
      Offset bestStart = fromVs.rightPort;
      for (final name in NodeViewState.portNames) {
        final portPos = fromVs.getPortPosition(name);
        final dist = (portPos - overrideEnd).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestStart = portPos;
        }
      }
      start = bestStart;
    }
    // 3. Normal routing (neither side is overridden)
    else if (overrideStart == null && overrideEnd == null && startSize != Size.zero && endSize != Size.zero &&
        ((fromSide == null || fromSide == 'Auto') || (toSide == null || toSide == 'Auto'))) {
      if (fromSide != null && fromSide != 'Auto') {
        final explicitStart = fromVs.getPortPosition(fromSide);
        double bestDist = double.infinity;
        Offset bestEnd = toVs.leftPort;
        for (final name in NodeViewState.portNames) {
          final portPos = toVs.getPortPosition(name);
          final dist = (explicitStart - portPos).distance;
          if (dist < bestDist) {
            bestDist = dist;
            bestEnd = portPos;
          }
        }
        start = explicitStart;
        end = bestEnd;
      } else if (toSide != null && toSide != 'Auto') {
        final explicitEnd = toVs.getPortPosition(toSide);
        double bestDist = double.infinity;
        Offset bestStart = fromVs.rightPort;
        for (final name in NodeViewState.portNames) {
          final portPos = fromVs.getPortPosition(name);
          final dist = (portPos - explicitEnd).distance;
          if (dist < bestDist) {
            bestDist = dist;
            bestStart = portPos;
          }
        }
        start = bestStart;
        end = explicitEnd;
      } else {
        double bestDist = double.infinity;
        Offset bestStart = fromVs.rightPort;
        Offset bestEnd = toVs.leftPort;
        for (final fromName in NodeViewState.portNames) {
          final fromPortPos = fromVs.getPortPosition(fromName);
          for (final toName in NodeViewState.portNames) {
            final toPortPos = toVs.getPortPosition(toName);
            final dist = (fromPortPos - toPortPos).distance;
            if (dist < bestDist) {
              bestDist = dist;
              bestStart = fromPortPos;
              bestEnd = toPortPos;
            }
          }
        }
        start = bestStart;
        end = bestEnd;
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
    String bestSide = 'Right';
    double bestDist = double.infinity;
    for (final name in NodeViewState.portNames) {
      final portPos = vs.getPortPosition(name);
      final dist = (portPos - offset).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestSide = name;
      }
    }
    if (bestDist < 2.0) {
      return bestSide;
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
