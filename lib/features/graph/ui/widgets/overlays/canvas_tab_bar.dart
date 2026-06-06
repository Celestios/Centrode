import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import '../../../presentation/workspace_tabs_controller.dart';

import 'package:mycelium/presentation/widgets/hover_scale_button.dart';

class CanvasTabBar extends StatelessWidget {
  const CanvasTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final tabs = tabsController.tabs;
    final activeIndex = tabsController.activeIndex;

    return GlassGroup(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tabs.length, (index) {
                  final session = tabs[index];
                  final isActive = index == activeIndex;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabItem(
                      name: session.name,
                      isActive: isActive,
                      canClose: tabs.length > 1,
                      onTap: () => tabsController.selectTab(index),
                      onClose: () => tabsController.closeTab(index),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _AddTabButton(tabsController: tabsController),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab item
// -----------------------------------------------------------------------------

class _TabItem extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.name,
    required this.isActive,
    required this.canClose,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final activeColor = onSurface;
    final inactiveColor = onSurface.withValues(alpha: 0.6);

    return HoverScaleButton(
      onTap: onTap,
      hoverScale: 1.04,
      pressScale: 0.96,
      borderRadius: BorderRadius.circular(10),
      builder: (context, isHovered, isPressed) {
        return GlassPanel(
          borderRadius: 10,
          color: isActive
              ? theme.cardColor.withValues(alpha: 0.72)
              : (isHovered
                    ? theme.cardColor.withValues(alpha: 0.60)
                    : theme.cardColor.withValues(alpha: 0.45)),
          shadow: isActive
              ? BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: isActive
                      ? activeColor
                      : (isHovered ? primaryColor : inactiveColor),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? activeColor
                        : (isHovered ? primaryColor : inactiveColor),
                  ),
                ),
                if (canClose) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close_rounded,
                      color: isActive
                          ? activeColor.withValues(alpha: 0.6)
                          : (isHovered
                                ? primaryColor.withValues(alpha: 0.6)
                                : inactiveColor.withValues(alpha: 0.6)),
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Add tab button
// -----------------------------------------------------------------------------

class _AddTabButton extends StatelessWidget {
  final WorkspaceTabsController tabsController;

  const _AddTabButton({required this.tabsController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return HoverScaleButton(
      onTap: () {
        final newIndex = tabsController.tabs.length + 1;
        tabsController.addTab(
          'maps/mycelium_tab_$newIndex.db',
          'Map $newIndex',
        );
      },
      hoverScale: 1.05,
      pressScale: 0.95,
      borderRadius: BorderRadius.circular(10),
      builder: (context, isHovered, isPressed) {
        return GlassPanel(
          borderRadius: 10,
          color: isHovered
              ? theme.cardColor.withValues(alpha: 0.68)
              : theme.cardColor.withValues(alpha: 0.45),
          shadow: isHovered
              ? BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              Icons.add_rounded,
              color: isHovered
                  ? primaryColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 14,
            ),
          ),
        );
      },
    );
  }
}
