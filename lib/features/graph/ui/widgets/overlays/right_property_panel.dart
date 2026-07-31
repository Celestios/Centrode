import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';
import 'collapsible_sidebar.dart';
import 'package:centrode/shared/utils/color_utils.dart';
import 'inspector/appearance_tab.dart';
import 'inspector/data_tab.dart';

class RightPropertyPanel extends StatefulWidget {
  const RightPropertyPanel({super.key});

  @override
  State<RightPropertyPanel> createState() => _RightPropertyPanelState();
}

class _RightPropertyPanelState extends State<RightPropertyPanel> {
  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<NodeRenderState, bool>(
      (s) => s.selectedEntities.isNotEmpty,
    );
    final renderState = context.read<NodeRenderState>();
    final selectedEntities = renderState.selectedEntities;

    return CollapsibleSidebar(
      title: 'INSPECTOR',
      icon: Icons.tune_rounded,
      isRight: true,
      isVisible: isSelected,
      showHeader: false,
      expandedWidth: 260.0,
      child: isSelected
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(context, renderState),
                ValueListenableBuilder<InspectorTab>(
                  valueListenable: renderState.activeInspectorTabNotifier,
                  builder: (context, activeTab, _) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: activeTab == InspectorTab.appearance
                          ? AppearanceTab(
                              selectedEntities: selectedEntities,
                              renderState: renderState,
                            )
                          : DataTab(
                              nodeId: selectedEntities.first,
                              renderState: renderState,
                            ),
                    );
                  },
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTabBar(BuildContext context, NodeRenderState renderState) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<InspectorTab>(
      valueListenable: renderState.activeInspectorTabNotifier,
      builder: (context, activeTab, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          context,
                          label: 'Appearance',
                          isActive: activeTab == InspectorTab.appearance,
                          onTap: () {
                            renderState.activeInspectorTabNotifier.value =
                                InspectorTab.appearance;
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          context,
                          label: 'Data',
                          isActive: activeTab == InspectorTab.data,
                          onTap: () {
                            renderState.activeInspectorTabNotifier.value =
                                InspectorTab.data;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${renderState.selectedEntities.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isPanelDark = ColorUtils.isDark(theme.cardColor);
    final activeBgColor = theme.colorScheme.primary;
    final activeTextColor = ColorUtils.getContrastTextColor(activeBgColor);
    final inactiveTextColor = isPanelDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}
