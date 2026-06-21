import 'dart:ui';
import 'package:mycelium/features/graph/models/port.dart';
import '../engine/config.dart';

class NodePorts {
  static const _cardinalSides = [PortSide.top, PortSide.right, PortSide.bottom, PortSide.left];

  final List<Port> ports;
  final Map<PortSide, List<Port>> _bySide;

  NodePorts._(this.ports, this._bySide);

  factory NodePorts.compute(Size nodeSize, double scale, {Offset nodePosition = Offset.zero}) {
    final offset = AppConfig.port.edgeOffset * scale;
    final ports = <Port>[];
    final bySide = <PortSide, List<Port>>{};
    final seenPositions = <Offset>{};

    for (final side in _cardinalSides) {
      final count = 3;
      final sidePorts = <Port>[];

      for (int i = 0; i < count; i++) {
        final t = count == 1 ? 0.5 : i / (count - 1);
        final localPosition = _positionOnSide(side, nodeSize, t);
        final edgePos = nodePosition + localPosition;

        if (seenPositions.contains(edgePos)) continue;
        seenPositions.add(edgePos);

        final type = _portType(i, count);
        final adjacentSide = _adjacentSide(side, i, count);
        final portSide = type == PortType.corner ? _cornerSide(side, i, count) : side;

        final visualPos = _visualOffset(portSide, type, edgePos, offset, nodePosition);

        final port = Port(
          side: portSide,
          type: type,
          index: i,
          position: visualPos,
          edgePosition: edgePos,
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

  List<Port> portsByType(PortType type) => ports.where((p) => p.type == type).toList();

  Port? getClosestPortByType(Offset point, PortType type) {
    double bestDist = double.infinity;
    Port? bestPort;
    for (final port in ports) {
      if (port.type != type) continue;
      final dist = (point - port.position).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestPort = port;
      }
    }
    return bestPort;
  }

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

  static Offset _visualOffset(PortSide side, PortType type, Offset edgePos, double d, Offset nodePosition) {
    if (type == PortType.corner) {
      final isLeft = edgePos.dx <= nodePosition.dx;
      final isTop = edgePos.dy <= nodePosition.dy;
      return edgePos + Offset(isLeft ? -d : d, isTop ? -d : d);
    }
    switch (side) {
      case PortSide.top:
        return edgePos + Offset(0, -d);
      case PortSide.bottom:
        return edgePos + Offset(0, d);
      case PortSide.left:
        return edgePos + Offset(-d, 0);
      case PortSide.right:
        return edgePos + Offset(d, 0);
      default:
        return edgePos;
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
      default:
        return Offset(size.width * t, 0);
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

  static PortSide _cornerSide(PortSide side, int index, int count) {
    if (index == 0) {
      switch (side) {
        case PortSide.top:     return PortSide.topLeft;
        case PortSide.right:   return PortSide.topRight;
        case PortSide.bottom:  return PortSide.bottomLeft;
        case PortSide.left:    return PortSide.topLeft;
        default:               return side;
      }
    } else {
      switch (side) {
        case PortSide.top:     return PortSide.topRight;
        case PortSide.right:   return PortSide.bottomRight;
        case PortSide.bottom:  return PortSide.bottomRight;
        case PortSide.left:    return PortSide.bottomLeft;
        default:               return side;
      }
    }
  }

  static PortSide? _adjacentSide(PortSide side, int index, int count) {
    if (index == 0) {
      switch (side) {
        case PortSide.top:     return PortSide.left;
        case PortSide.right:   return PortSide.top;
        case PortSide.bottom:  return PortSide.right;
        case PortSide.left:    return PortSide.bottom;
        default:               return null;
      }
    }
    if (index == count - 1) {
      switch (side) {
        case PortSide.top:     return PortSide.right;
        case PortSide.right:   return PortSide.bottom;
        case PortSide.bottom:  return PortSide.left;
        case PortSide.left:    return PortSide.top;
        default:               return null;
      }
    }
    return null;
  }
}
