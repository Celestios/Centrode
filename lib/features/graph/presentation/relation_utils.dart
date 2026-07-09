import 'dart:ui';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

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

List<Offset> transformPathPoints({
  required List<Offset> points,
  required Offset sourceStart,
  required Offset sourceEnd,
  required Offset targetStart,
  required Offset targetEnd,
}) {
  if (points.isEmpty) return [];
  final u0 = sourceEnd - sourceStart;
  final double l0 = u0.distance;
  final Offset dir0 = l0 > 1e-6 ? u0 / l0 : const Offset(1, 0);
  final Offset perp0 = Offset(-dir0.dy, dir0.dx);

  final Offset u = targetEnd - targetStart;
  final double l = u.distance;
  final Offset dir = l > 1e-6 ? u / l : dir0;
  final Offset perp = Offset(-dir.dy, dir.dx);

  return points.map((p) {
    final delta0 = p - sourceStart;
    final double x = delta0.dx * dir0.dx + delta0.dy * dir0.dy;
    final double y = delta0.dx * perp0.dx + delta0.dy * perp0.dy;
    final double xPrime = x * (l0 > 1e-6 ? (l / l0) : 1.0);
    final double yPrime = y;
    return targetStart + dir * xPrime + perp * yPrime;
  }).toList();
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
