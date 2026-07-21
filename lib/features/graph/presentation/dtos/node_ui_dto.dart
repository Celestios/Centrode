import 'dart:ui';

class NodeUiDto {
  final String id;
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
