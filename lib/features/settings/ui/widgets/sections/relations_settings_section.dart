import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'top_sections.dart';

class RelationsSettingsSection extends StatelessWidget {
  const RelationsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCardWrapper(
      title: 'Pathfinding & Geometry Routing',
      subtitle: 'Obstacle avoidance clearance and corner radius filleting',
      child: Text(
        'Relation routing modes (Polyline, Orthogonal, Bezier) are active with system defaults.',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
          fontSize: UiFont.standard,
        ),
      ),
    );
  }
}
