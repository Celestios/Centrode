import 'package:flutter/material.dart';

/// Routing strategy item descriptor.
class RelationRoutingDefinition {
  final String id;
  final String label;
  final IconData icon;

  const RelationRoutingDefinition({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const List<RelationRoutingDefinition> kAvailableRoutingStrategies = [
  RelationRoutingDefinition(id: 'straight', label: 'Straight', icon: Icons.show_chart_rounded),
  RelationRoutingDefinition(id: 'curved', label: 'Bézier', icon: Icons.gesture_rounded),
  RelationRoutingDefinition(id: 'ortho', label: 'Orthogonal', icon: Icons.alt_route_rounded),
  RelationRoutingDefinition(id: 'step', label: 'Step', icon: Icons.turn_right_rounded),
];

/// Cap style item descriptor.
class RelationCapDefinition {
  final String id;
  final String label;
  final IconData icon;

  const RelationCapDefinition({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const List<RelationCapDefinition> kAvailableStartCaps = [
  RelationCapDefinition(id: 'none', label: 'None', icon: Icons.remove_rounded),
  RelationCapDefinition(id: 'circle', label: 'Dot', icon: Icons.circle_outlined),
  RelationCapDefinition(id: 'diamond', label: 'Diamond', icon: Icons.diamond_outlined),
  RelationCapDefinition(id: 'square', label: 'Square', icon: Icons.crop_square_rounded),
];

const List<RelationCapDefinition> kAvailableEndCaps = [
  RelationCapDefinition(id: 'arrow', label: 'Arrow', icon: Icons.arrow_forward_rounded),
  RelationCapDefinition(id: 'diamond', label: 'Diamond', icon: Icons.diamond_outlined),
  RelationCapDefinition(id: 'circle', label: 'Dot', icon: Icons.circle_outlined),
  RelationCapDefinition(id: 'none', label: 'None', icon: Icons.remove_rounded),
];
