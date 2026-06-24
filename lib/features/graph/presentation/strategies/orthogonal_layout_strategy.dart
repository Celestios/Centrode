import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../routing/relation_layout_context.dart';
import '../routing/relation_router.dart';
import 'relation_layout_strategy.dart';

class OrthogonalRelationLayoutStrategy extends RelationLayoutStrategy {
  const OrthogonalRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return calculateLabelHitArea();
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

      final corner1 = Offset(p2.dx, p1.dy);
      final corner2 = Offset(p1.dx, p2.dy);

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
        points.add(corner1);
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
    final orthoPoints = getOrthoPoints(
      start,
      end,
      fromVs,
      toVs,
      relation,
      context,
    );
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
    final orthoPoints = getOrthoPoints(
      start,
      end,
      fromVs,
      toVs,
      relation,
      context,
    );
    if (orthoPoints.length < 2) return (start + end) / 2;
    return midpointOnPolyline(orthoPoints);
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
    final orthoPoints = getOrthoPoints(
      start,
      end,
      fromVs,
      toVs,
      relation,
      context,
    );
    if (orthoPoints.length < 2) {
      return distanceToSegment(p, start, end) <= threshold;
    }
    return isPointNearPolyline(p, orthoPoints, threshold);
  }
}
