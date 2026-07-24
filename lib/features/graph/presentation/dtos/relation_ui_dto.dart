import 'dart:ui';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class RelationUiDto {
  final RawUuid id;
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
