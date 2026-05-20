import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

/// Responsible for computing the physical size, bounds, or layout positions for a relation.
abstract class RelationLayoutStrategy {
  const RelationLayoutStrategy();

  /// Calculates the size of the relation elements (e.g., label bounding box).
  Size calculate(UiRelation relation, RelationStyle style);

  /// Resolves the start and end offsets for drawing this relation,
  /// using either the persisted layout sides, dynamic calculations, or drag overrides.
  static (Offset, Offset) resolveEndpoints(
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

  /// Resolves positions for the tip handles, placed slightly before the start and end tips.
  static (Offset, Offset) resolveTipHandles(
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
}

class DefaultRelationLayoutStrategy extends RelationLayoutStrategy {
  const DefaultRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    return AppConfig.interaction.relationLabelHitArea;
  }
}
