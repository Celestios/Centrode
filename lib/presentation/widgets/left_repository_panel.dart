import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

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
      borderRadius: 12.0,
      color: theme.cardColor.withValues(alpha: 0.90),
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
        width: UiStrokeWidth.standard,
      ),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0, right: 16.0),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
