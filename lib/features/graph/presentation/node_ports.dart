import 'dart:math';
import 'dart:ui';
import 'package:mycelium/features/graph/models/port.dart';

class NodePorts {
  final List<Port> ports;
  final Map<PortSide, List<Port>> _bySide;

  NodePorts._(this.ports, this._bySide);

  factory NodePorts.compute(Size nodeSize, double scale, {Offset nodePosition = Offset.zero}) {
    const baseDistance = 40.0;
    final k = baseDistance * scale;
    final ports = <Port>[];
    final bySide = <PortSide, List<Port>>{};
    final seenPositions = <Offset>{};

    for (final side in PortSide.values) {
      final sideLength = _sideLength(side, nodeSize);
      final count = max(3, (sideLength / k).floor());
      final sidePorts = <Port>[];

      for (int i = 0; i < count; i++) {
        final t = count == 1 ? 0.5 : i / (count - 1);
        final localPosition = _positionOnSide(side, nodeSize, t);
        final position = nodePosition + localPosition;

        // Skip duplicate corner positions
        if (seenPositions.contains(position)) continue;
        seenPositions.add(position);

        final type = _portType(i, count);
        final adjacentSide = _adjacentSide(side, i, count);

        final port = Port(
          side: side,
          type: type,
          index: i,
          position: position,
          adjacentSide: adjacentSide,
        );
        sidePorts.add(port);
        ports.add(port);
      }

      bySide[side] = sidePorts;
    }

    return NodePorts._(ports, bySide);
  }

  List<Port> get allPorts => ports;

  Port? getClosestPort(Offset point) {
    double bestDist = double.infinity;
    Port? bestPort;

    for (final port in ports) {
      final dist = (point - port.position).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestPort = port;
      }
    }

    return bestPort;
  }

  Port? getMiddlePortForSide(PortSide side) {
    final sidePorts = _bySide[side];
    if (sidePorts == null || sidePorts.isEmpty) return null;
    return sidePorts.firstWhere(
      (p) => p.isMiddle,
      orElse: () => sidePorts[sidePorts.length ~/ 2],
    );
  }

  static double _sideLength(PortSide side, Size size) {
    switch (side) {
      case PortSide.top:
      case PortSide.bottom:
        return size.width;
      case PortSide.left:
      case PortSide.right:
        return size.height;
    }
  }

  static Offset _positionOnSide(PortSide side, Size size, double t) {
    switch (side) {
      case PortSide.top:
        return Offset(size.width * t, 0);
      case PortSide.right:
        return Offset(size.width, size.height * t);
      case PortSide.bottom:
        return Offset(size.width * t, size.height);
      case PortSide.left:
        return Offset(0, size.height * t);
    }
  }

  static PortType _portType(int index, int count) {
    if (index == 0 || index == count - 1) return PortType.corner;
    if (count.isOdd && index == count ~/ 2) return PortType.middle;
    if (count.isEven && (index == count ~/ 2 - 1 || index == count ~/ 2)) {
      return PortType.middle;
    }
    return PortType.edge;
  }

  static PortSide? _adjacentSide(PortSide side, int index, int count) {
    if (index == 0) {
      switch (side) {
        case PortSide.top:
          return PortSide.left;
        case PortSide.right:
          return PortSide.top;
        case PortSide.bottom:
          return PortSide.right;
        case PortSide.left:
          return PortSide.bottom;
      }
    }
    if (index == count - 1) {
      switch (side) {
        case PortSide.top:
          return PortSide.right;
        case PortSide.right:
          return PortSide.bottom;
        case PortSide.bottom:
          return PortSide.left;
        case PortSide.left:
          return PortSide.top;
      }
    }
    return null;
  }
}
