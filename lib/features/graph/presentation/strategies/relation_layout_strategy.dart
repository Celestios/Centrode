export 'straight_layout_strategy.dart';
export 'bezier_layout_strategy.dart';
export 'orthogonal_layout_strategy.dart';
export 'snake_layout_strategy.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../routing/relation_layout_context.dart';
import '../routing/relation_router.dart';
import 'straight_layout_strategy.dart';
import 'bezier_layout_strategy.dart';
import 'orthogonal_layout_strategy.dart';
import 'snake_layout_strategy.dart';

abstract class RelationLayoutStrategy {
  const RelationLayoutStrategy();

  static RelationLayoutStrategy fromType(String? type) {
    if (type == 'bezier') {
      return const BezierRelationLayoutStrategy();
    }
    if (type == 'orthogonal') {
      return const OrthogonalRelationLayoutStrategy();
    }
    if (type == 'snake') {
      return const SnakeRelationLayoutStrategy();
    }
    return const StraightRelationLayoutStrategy();
  }

  Size calculate(UiRelation relation, RelationStyle style);

  Size calculateLabelHitArea() {
    return AppConfig.interaction.relationLabelHitArea;
  }

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
    } else if (fromSide != null) {
      start = fromVs.getPortPosition(fromSide);
    } else {
      start = fromVs.rightPort;
    }

    if (overrideEnd != null) {
      end = overrideEnd;
    } else if (endSize == Size.zero) {
      end = toVs.positionNotifier.value + AppConfig.relation.endFallback;
    } else if (toSide != null) {
      end = toVs.getPortPosition(toSide);
    } else {
      end = toVs.leftPort;
    }

    if (overrideStart != null &&
        overrideEnd == null &&
        endSize != Size.zero &&
        toSide == null) {
      end = toVs.getClosestPort(overrideStart).position;
    } else if (overrideEnd != null &&
        overrideStart == null &&
        startSize != Size.zero &&
        fromSide == null) {
      start = fromVs.getClosestPort(overrideEnd).position;
    } else if (overrideStart == null &&
        overrideEnd == null &&
        startSize != Size.zero &&
        endSize != Size.zero &&
        (fromSide == null || toSide == null)) {
      if (fromSide != null) {
        final explicitStart = fromVs.getPortPosition(fromSide);
        start = explicitStart;
        end = toVs.getClosestPort(explicitStart).position;
      } else if (toSide != null) {
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

  static ({Port startPort, Port endPort}) getClosestMiddlePorts(
    NodeViewState fromVs,
    NodeViewState toVs,
  ) {
    double bestDist = double.infinity;
    Port bestStart = fromVs.ports.getMiddlePortForSide(PortSide.right)!;
    Port bestEnd = toVs.ports.getMiddlePortForSide(PortSide.left)!;

    for (final fromPort in fromVs.getMiddlePorts()) {
      for (final toPort in toVs.getMiddlePorts()) {
        final dist = (fromPort.edgePosition - toPort.edgePosition).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestStart = fromPort;
          bestEnd = toPort;
        }
      }
    }

    return (startPort: bestStart, endPort: bestEnd);
  }

  Path computePath(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  );

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

    final path = computePath(start, end, fromVs, toVs, relation, context);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return (start, end);
    }
    final metric = metrics.first;
    final length = metric.length;

    if (length < 40.0) {
      final t1 = metric.getTangentForOffset(length * (1 / 3));
      final t2 = metric.getTangentForOffset(length * (2 / 3));
      return (
        t1?.position ?? (start + (end - start) * (1 / 3)),
        t2?.position ?? (start + (end - start) * (2 / 3)),
      );
    }

    final tStart = metric.getTangentForOffset(16.0);
    final tEnd = metric.getTangentForOffset(length - 16.0);

    return (tStart?.position ?? start, tEnd?.position ?? end);
  }

  Offset computeLabelPosition(
    Offset start,
    Offset end,
    NodeViewState fromVs,
    NodeViewState toVs,
    UiRelation relation,
    RelationLayoutContext context,
  );

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

  double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0.0) return ap.distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lenSq).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).distance;
  }

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

  Offset midpointOnPolyline(List<Offset> points) {
    if (points.length < 2) return points.first;

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final len = (points[i + 1] - points[i]).distance;
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
        return Offset.lerp(points[i], points[i + 1], t)!;
      }
      currentLength += len;
    }
    return points.last;
  }

  bool isPointNearPolyline(Offset p, List<Offset> points, double threshold) {
    if (points.length < 2) return false;
    for (int i = 0; i < points.length - 1; i++) {
      if (distanceToSegment(p, points[i], points[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }
}
