import 'dart:ui';
import 'package:centrode/shared/domain/raw_uuid.dart';

class NodeUiDto {
  final RawUuid id;
  final String type;
  final String label;
  final Offset position;
  final Size size;
  final Map<String, dynamic> styles;
  final List<String> tags;

  const NodeUiDto({
    required this.id,
    required this.type,
    required this.label,
    required this.position,
    required this.size,
    required this.styles,
    required this.tags,
  });
}
