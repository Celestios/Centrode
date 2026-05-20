import 'package:flutter/material.dart';
import 'collapsible_sidebar.dart';

class LeftRepositoryDrawer extends StatefulWidget {
  const LeftRepositoryDrawer({super.key});

  @override
  State<LeftRepositoryDrawer> createState() => _LeftRepositoryDrawerState();
}

class _LeftRepositoryDrawerState extends State<LeftRepositoryDrawer> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    return CollapsibleSidebar(
      title: 'REPOSITORY',
      isMinimized: _isMinimized,
      headerAction: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          _isMinimized
              ? Icons.keyboard_double_arrow_right_rounded
              : Icons.keyboard_double_arrow_left_rounded,
          color: textColor.withValues(alpha: 0.7),
          size: 18,
        ),
        onPressed: () => setState(() => _isMinimized = !_isMinimized),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Center(
          child: _isMinimized
              ? Icon(
                  Icons.folder_off_outlined,
                  color: textColor.withValues(alpha: 0.4),
                  size: 20,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      color: textColor.withValues(alpha: 0.3),
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No templates loaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
