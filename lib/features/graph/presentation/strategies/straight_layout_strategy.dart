import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../routing/relation_layout_context.dart';
import 'relation_layout_strategy.dart';

class StraightRelationLayoutStrategy extends RelationLayoutStrategy {
  const StraightRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return calculateLabelHitArea();
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
    return midpointOnPolyline(waypoints);
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
    return isPointNearPolyline(p, waypoints, threshold);
  }
}
