import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import '../../../presentation/graph_presentation_notifier.dart';
import 'package:mycelium/presentation/widgets/hover_scale_button.dart';

class CanvasToolRibbon extends StatefulWidget {
  const CanvasToolRibbon({super.key});

  @override
  State<CanvasToolRibbon> createState() => _CanvasToolRibbonState();
}

class _CanvasToolRibbonState extends State<CanvasToolRibbon> {
  bool _isCompact = false;

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final dataController = context.watch<GraphPresentationNotifier>().controller;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final tools = [
      (icon: Icons.near_me_outlined, label: 'Select', mode: 'select'),
      (icon: Icons.pan_tool_outlined, label: 'Pan', mode: 'pan'),
      (icon: Icons.timeline_outlined, label: 'Connect', mode: 'connect'),
    ];

    final actions = [
      (
        icon: Icons.undo_rounded,
        tooltip: dataController.canUndo
            ? 'Undo (${dataController.undoCount} actions remaining)'
            : 'Undo (No actions available)',
        action: dataController.undo,
        showAlways: true,
        isEnabled: dataController.canUndo,
        count: dataController.undoCount,
      ),
      (
        icon: Icons.redo_rounded,
        tooltip: dataController.canRedo
            ? 'Redo (${dataController.redoCount} actions remaining)'
            : 'Redo (No actions available)',
        action: dataController.redo,
        showAlways: true,
        isEnabled: dataController.canRedo,
        count: dataController.redoCount,
      ),
      (
        icon: Icons.file_download_outlined,
        tooltip: 'Import Map',
        action: () {},
        showAlways: false,
        isEnabled: true,
        count: 0,
      ),
      (
        icon: Icons.file_upload_outlined,
        tooltip: 'Export Map',
        action: () {},
        showAlways: false,
        isEnabled: true,
        count: 0,
      ),
    ];

    return GlassPanel(
      blur: 12,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact Toggle button on the left
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isCompact
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              color: textColor.withValues(alpha: 0.7),
              size: 20,
            ),
            tooltip: _isCompact ? 'Expand ribbon' : 'Compact ribbon',
            onPressed: () {
              setState(() {
                _isCompact = !_isCompact;
              });
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 1.5,
            height: 24,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),

          // Tool Mode selection
          ValueListenableBuilder<String>(
            valueListenable: session.toolModeNotifier,
            builder: (context, currentMode, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < tools.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _ToolButton(
                      icon: tools[i].icon,
                      label: tools[i].label,
                      isActive: currentMode == tools[i].mode,
                      isCompact: _isCompact,
                      onPressed: () =>
                          session.toolModeNotifier.value = tools[i].mode,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(width: 8),
          Container(
            width: 1.5,
            height: 24,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),

          // Action controls: Undo, Redo, Import, Export
          for (final act in actions)
            if (act.showAlways || !_isCompact)
              _ActionButton(
                icon: act.icon,
                tooltip: act.tooltip,
                onPressed: act.action,
                textColor: textColor,
                isEnabled: act.isEnabled,
                count: act.count,
              ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCompact;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color textColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCompact,
    required this.onPressed,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = primaryColor;
    final inactiveColor = textColor.withValues(alpha: 0.7);

    return HoverScaleButton(
      onTap: onPressed,
      hoverScale: 1.04,
      pressScale: 0.96,
      borderRadius: BorderRadius.circular(10),
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.28),
                      primaryColor.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : (isHovered
                      ? LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.18),
                            primaryColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.45)
                  : (isHovered
                        ? activeColor.withValues(alpha: 0.25)
                        : Colors.transparent),
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isHovered
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.08),
                            blurRadius: 4,
                            spreadRadius: -1,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : []),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? textColor
                    : (isHovered ? activeColor : inactiveColor),
                size: 18,
              ),
              if (!isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? textColor
                        : (isHovered ? activeColor : inactiveColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color textColor;
  final bool isEnabled;
  final int count;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.textColor,
    this.isEnabled = true,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HoverScaleButton(
      onTap: isEnabled ? onPressed : null,
      isEnabled: isEnabled,
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(8),
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isEnabled && isHovered
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.18),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: isEnabled && isHovered
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.0,
                  )
                : Border.all(color: Colors.transparent),
            boxShadow: isEnabled && isHovered
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: !isEnabled
                    ? textColor.withValues(alpha: 0.25)
                    : (isHovered
                          ? theme.colorScheme.primary
                          : textColor.withValues(alpha: 0.7)),
                size: 18,
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: IgnorePointer(
                    child: AnimatedScale(
                      scale: count > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: count > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.4,
                              ),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                              child: Text(
                                '$count',
                                key: ValueKey<int>(count),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
