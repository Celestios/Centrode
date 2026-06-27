import 'dart:ui';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

(Offset start, Offset end) resolveRelationEndpoints(
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

({Port startPort, Port endPort}) getClosestMiddlePorts(
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

Path buildSimpleBezierPath(Offset start, Offset end) {
  final dx = (end.dx - start.dx).abs() * 0.4;
  final ctrl1 = Offset(
    start.dx + (end.dx > start.dx ? dx : -dx),
    start.dy,
  );
  final ctrl2 = Offset(
    end.dx - (end.dx > start.dx ? dx : -dx),
    end.dy,
  );
  return Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);
}

double distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;
  final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lenSq == 0.0) return ap.distance;

  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lenSq).clamp(0.0, 1.0);
  final projection = a + ab * t;
  return (p - projection).distance;
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
