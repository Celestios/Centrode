import 'dart:ui';
import 'package:centrode/src/rust/domain/styles.dart' show PortSide;

export 'package:centrode/src/rust/domain/styles.dart' show PortSide;

enum PortType { corner, middle, edge }

class Port {
  final PortSide side;
  final PortType type;
  final int index;
  final Offset position;
  final Offset edgePosition;
  final PortSide? adjacentSide;

  const Port({
    required this.side,
    required this.type,
    required this.index,
    required this.position,
    required this.edgePosition,
    this.adjacentSide,
  });

  bool get isCorner => type == PortType.corner;
  bool get isMiddle => type == PortType.middle;
  bool get isEdge => type == PortType.edge;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Port &&
          runtimeType == other.runtimeType &&
          side == other.side &&
          type == other.type &&
          index == other.index;

  @override
  int get hashCode => Object.hash(side, type, index);

  @override
  String toString() => 'Port(${side.name}, ${type.name}, $index)';
}
