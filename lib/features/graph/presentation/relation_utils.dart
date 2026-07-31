import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
export 'package:centrode/shared/utils/geometry.dart';

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
