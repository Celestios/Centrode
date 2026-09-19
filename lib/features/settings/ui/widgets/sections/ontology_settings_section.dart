import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'top_sections.dart';

class OntologySettingsSection extends StatelessWidget {
  const OntologySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCardWrapper(
      title: 'Controlled Vocabulary & Embeddings',
      subtitle: 'Soft forced ontology and 384-dimensional vector similarity',
      child: Text(
        'Controlled predicate dictionary and AI reasoning context depth are active with system defaults.',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
          fontSize: UiFont.standard,
        ),
      ),
    );
  }
}
