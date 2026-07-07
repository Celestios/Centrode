import 'dart:ui';

class RelationViewStateRecord {
  final String nodeId;
  final Offset position;
  final Size size;
  final Map<String, Offset> ports;

  const RelationViewStateRecord({
    required this.nodeId,
    required this.position,
    required this.size,
    required this.ports,
  });
}
