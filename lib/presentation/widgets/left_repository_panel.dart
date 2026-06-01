import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

class LeftRepositoryPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const LeftRepositoryPanel({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      padding: EdgeInsets.zero,
      blur: 12.0,
      borderRadius: 16.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
