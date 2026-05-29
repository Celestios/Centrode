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
        tooltip: 'Undo',
        action: dataController.undo,
        showAlways: true,
      ),
      (
        icon: Icons.redo_rounded,
        tooltip: 'Redo',
        action: dataController.redo,
        showAlways: true,
      ),
      (
        icon: Icons.file_download_outlined,
        tooltip: 'Import Map',
        action: () {},
        showAlways: false,
      ),
      (
        icon: Icons.file_upload_outlined,
        tooltip: 'Export Map',
        action: () {},
        showAlways: false,
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

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.textColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: _isHovered
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: _isHovered
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : [],
            ),
            child: AnimatedScale(
              scale: _isHovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                widget.icon,
                color: _isHovered
                    ? theme.colorScheme.primary
                    : widget.textColor.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
