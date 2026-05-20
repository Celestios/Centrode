import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'glass_panel.dart';

class CanvasTabBar extends StatelessWidget {
  const CanvasTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final tabs = tabsController.tabs;
    final activeIndex = tabsController.activeIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: _buildTabItem(
                      context: context,
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
          _buildAddTabButton(context, tabsController),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required String name,
    required bool isActive,
    required bool canClose,
    required VoidCallback onTap,
    required VoidCallback onClose,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    
    final activeColor = primaryColor;
    final inactiveColor = onSurface.withValues(alpha: 0.6);

    return GlassPanel(
      fallbackBorderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onTap: onTap,
      duration: const Duration(milliseconds: 200),
      backgroundColor: isActive
          ? primaryColor.withValues(alpha: 0.12)
          : theme.cardColor.withValues(alpha: 0.6),
      border: Border.all(
        color: isActive
            ? primaryColor.withValues(alpha: 0.4)
            : theme.dividerColor.withValues(alpha: 0.3),
        width: 1.0,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.05),
                blurRadius: 8,
              )
            ]
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: isActive ? activeColor : inactiveColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? activeColor : inactiveColor,
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
                    : inactiveColor.withValues(alpha: 0.6),
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddTabButton(
    BuildContext context,
    WorkspaceTabsController tabsController,
  ) {
    final theme = Theme.of(context);

    return GlassPanel(
      fallbackBorderRadius: 10,
      alpha: 0.6,
      padding: const EdgeInsets.all(7),
      onTap: () {
        final newIndex = tabsController.tabs.length + 1;
        tabsController.addTab(
          'maps/mycelium_tab_$newIndex.db',
          'Map $newIndex',
        );
      },
      child: Icon(
        Icons.add_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        size: 14,
      ),
    );
  }
}
