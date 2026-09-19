import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'top_sections.dart';

class PhysicsSettingsSection extends StatelessWidget {
  const PhysicsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCardWrapper(
      title: 'Force-Directed Physics',
      subtitle: 'Active sub-graph layout engine constants',
      child: Text(
        'Physics simulation forces (Coulomb repulsion, Hooke spring stiffness, velocity damping) are active with system defaults.',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
          fontSize: UiFont.standard,
        ),
      ),
    );
  }
}
