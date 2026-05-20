import 'package:flutter/material.dart';
import 'glass_panel.dart';

class CollapsibleSidebar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isRight;
  final bool isVisible;
  final double expandedWidth;
  final double collapsedWidth;
  final bool isMinimized;
  final Widget? headerAction;
  final Widget child;

  const CollapsibleSidebar({
    super.key,
    required this.title,
    this.icon,
    this.isRight = false,
    this.isVisible = true,
    this.expandedWidth = 220.0,
    this.collapsedWidth = 52.0,
    this.isMinimized = false,
    this.headerAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final double targetWidth = isVisible
        ? (isMinimized ? collapsedWidth : expandedWidth)
        : 0.0;

    return GlassPanel(
      fallbackBorderRadius: 16,
      blur: isVisible ? 12.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: targetWidth,
      border: isVisible
          ? null
          : Border.all(color: Colors.transparent, width: 0),
      boxShadow: isVisible
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: Offset(isRight ? -3 : 3, 3),
              ),
            ]
          : [],
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: expandedWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: isMinimized ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (headerAction != null) headerAction!,
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
