import 'dart:ui';

class RelationUiDto {
  final String id;
  final String sourceId;
  final String targetId;
  final List<Offset> pathPoints;
  final String style;
  final String label;

  const RelationUiDto({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.pathPoints,
    required this.style,
    required this.label,
  });
}
