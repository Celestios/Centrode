import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import '../../../store/graph_data_controller.dart';
import 'glass_panel.dart';

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
    final dataController = context.watch<GraphDataController>();

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassPanel(
        fallbackBorderRadius: 16,
        blur: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

            const SizedBox(width: 8),
            Container(
              width: 1.5,
              height: 24,
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),

            // Compact Toggle button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _isCompact ? Icons.menu_open_rounded : Icons.menu_rounded,
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
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
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
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.primaryColor;
    final inactiveColor = widget.textColor.withValues(alpha: 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 8 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.28),
                      widget.primaryColor.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : (_isHovered
                    ? LinearGradient(
                        colors: [
                          widget.primaryColor.withValues(alpha: 0.18),
                          widget.primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null),
            border: Border.all(
              color: widget.isActive
                  ? activeColor.withValues(alpha: 0.45)
                  : (_isHovered ? activeColor.withValues(alpha: 0.25) : Colors.transparent),
              width: 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    )
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.08),
                          blurRadius: 4,
                          spreadRadius: -1,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : []),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  color: widget.isActive
                      ? widget.textColor
                      : (_isHovered ? activeColor : inactiveColor),
                  size: 18,
                ),
              ),
              if (!widget.isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                    color: widget.isActive
                        ? widget.textColor
                        : (_isHovered ? activeColor : inactiveColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.isEnabled;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
        onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isEnabled && _isHovered
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: isEnabled && _isHovered
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isEnabled && _isHovered
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isEnabled && _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    widget.icon,
                    color: !isEnabled
                        ? widget.textColor.withValues(alpha: 0.25)
                        : (_isHovered
                            ? theme.colorScheme.primary
                            : widget.textColor.withValues(alpha: 0.7)),
                    size: 18,
                  ),
                ),
                if (widget.count > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IgnorePointer(
                      child: AnimatedScale(
                        scale: widget.count > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: widget.count > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
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
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  '${widget.count}',
                                  key: ValueKey<int>(widget.count),
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
          ),
        ),
      ),
    );
  }
}
