import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../routing/relation_layout_context.dart';
import 'relation_layout_strategy.dart';

class BezierRelationLayoutStrategy extends RelationLayoutStrategy {
  const BezierRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return calculateLabelHitArea();
  }

  Offset _getPortNormal(Port? port, Offset start, Offset end) {
    if (port == null) {
      final dir = end - start;
      if (dir.distance < 1.0) return const Offset(1, 0);
      return dir / dir.distance;
    }

    const s = 1 / sqrt2;
    switch (port.side) {
      case PortSide.left:
        return const Offset(-1, 0);
      case PortSide.right:
        return const Offset(1, 0);
      case PortSide.top:
        return const Offset(0, -1);
      case PortSide.bottom:
        return const Offset(0, 1);
      case PortSide.topLeft:
        return Offset(-s, -s);
      case PortSide.topRight:
        return Offset(s, -s);
      case PortSide.bottomLeft:
        return Offset(-s, s);
      case PortSide.bottomRight:
        return Offset(s, s);
      default:
        return const Offset(1, 0);
    }
  }

  Port? _resolveSideFromOffset(NodeViewState vs, Offset offset, PortSide? side) {
    if (side != null) {
      return vs.ports.getPortBySide(side) ?? vs.ports.getClosestPort(offset);
    }
    return vs.ports.getClosestPort(offset);
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

    final start = waypoints.first;
    final end = waypoints.last;
    final layout = relation.resolvedLayout ?? relation.layout;
    final fromSide = _resolveSideFromOffset(fromVs, start, layout?.fromSide);
    final toSide = _resolveSideFromOffset(toVs, end, layout?.toSide);

    final startNormal = _getPortNormal(fromSide, start, waypoints[1]);
    final endNormal = _getPortNormal(
      toSide,
      end,
      waypoints[waypoints.length - 2],
    );

    final points = <Offset>[];
    points.add(start - startNormal * 30.0);
    points.addAll(waypoints);
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
        final pt =
            start * (mt * mt * mt) +
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
    final endNormal = _getPortNormal(
      toSide,
      end,
      waypoints[waypoints.length - 2],
    );

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
        final pt =
            startPoint * (mt * mt) + pCurr * (2 * mt * t) + endPoint * (t * t);
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
    return midpointOnPolyline(samples);
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
    return isPointNearPolyline(p, samples, threshold);
  }
}
