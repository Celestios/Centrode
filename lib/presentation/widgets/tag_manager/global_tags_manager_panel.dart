import 'package:flutter/material.dart';
import '../../../features/graph/ui/widgets/overlays/glass_panel.dart';
import 'tags_list_view.dart';

class GlobalTagsManagerPanel extends StatelessWidget {
  const GlobalTagsManagerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: EdgeInsets.zero,
      blur: 12.0,
      alpha: 0.85,
      fallbackBorderRadius: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'GLOBAL TAGS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Expanded(
            child: TagsListView(),
          ),
        ],
      ),
    );
  }
}
