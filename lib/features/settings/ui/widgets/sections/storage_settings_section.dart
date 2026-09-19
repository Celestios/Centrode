import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'top_sections.dart';

class StorageSettingsSection extends StatelessWidget {
  const StorageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCardWrapper(
      title: 'Storage & Diagnostics',
      subtitle: 'SurrealDB workspace storage paths and telemetry log levels',
      child: Text(
        'Autosave intervals, .cent package formats, and disk logging are active with system defaults.',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
          fontSize: UiFont.standard,
        ),
      ),
    );
  }
}
