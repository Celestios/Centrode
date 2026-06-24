import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../routing/relation_layout_context.dart';
import 'relation_layout_strategy.dart';

class SnakeRelationLayoutStrategy extends RelationLayoutStrategy {
  final double amplitude;
  final double frequency;

  const SnakeRelationLayoutStrategy({
    this.amplitude = 20.0,
    this.frequency = 3.0,
  });

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
    final path = Path();
    final delta = end - start;
    final length = delta.distance;

    if (length < 1.0) {
      path.moveTo(start.dx, start.dy);
      return path;
    }

    final direction = delta / length;
    final normal = Offset(-direction.dy, direction.dx);
    final scaledFrequency = (length / 40.0).clamp(2.0, 20.0);

    const segments = 128;
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final pos = start + delta * t;
      final wave = sin(t * scaledFrequency * 2 * pi) * amplitude;
      final offset = normal * wave;
      path.lineTo(pos.dx + offset.dx, pos.dy + offset.dy);
    }

    return path;
  }

  List<Offset> _getSamplePoints(
    Offset start,
    Offset end,
  ) {
    final delta = end - start;
    final length = delta.distance;

    if (length < 1.0) return [start];

    final direction = delta / length;
    final normal = Offset(-direction.dy, direction.dx);
    final scaledFrequency = (length / 40.0).clamp(2.0, 20.0);

    const segments = 64;
    final samples = <Offset>[];

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final pos = start + delta * t;
      final wave = sin(t * scaledFrequency * 2 * pi) * amplitude;
      final offset = normal * wave;
      samples.add(pos + offset);
    }

    return samples;
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
    final samples = _getSamplePoints(start, end);
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
    final samples = _getSamplePoints(start, end);
    if (samples.length < 2) {
      return (p - start).distance <= threshold;
    }
    return isPointNearPolyline(p, samples, threshold);
  }
}
