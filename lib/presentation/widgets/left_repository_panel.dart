import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

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
    final accent = theme.colorScheme.error;
    final isDark = theme.brightness == Brightness.dark;
    return GlassPanel(
      padding: EdgeInsets.zero,
      blur: 12.0,
      borderRadius: UiRadius.panel,
      color: theme.cardColor.withValues(alpha: 0.90),
      gradient: RadialGradient(
        center: const Alignment(0.75, 0.85),
        radius: 0.95,
        colors: [
          accent.withValues(alpha: isDark ? 0.30 : 0.20),
          accent.withValues(alpha: isDark ? 0.15 : 0.08),
          accent.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
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
              color: theme.dividerColor,
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

