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
      (icon: Icons.undo_rounded, tooltip: 'Undo', action: dataController.undo, showAlways: true),
      (icon: Icons.redo_rounded, tooltip: 'Redo', action: dataController.redo, showAlways: true),
      (icon: Icons.file_download_outlined, tooltip: 'Import Map', action: () {}, showAlways: false),
      (icon: Icons.file_upload_outlined, tooltip: 'Export Map', action: () {}, showAlways: false),
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
                // Logo/Title (hidden in compact mode)
                if (!_isCompact) ...[
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                    ).createShader(bounds),
                    child: Text(
                      'MYCELIUM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1.5,
                    height: 24,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                ],

                // Tool Mode selection
                ValueListenableBuilder<String>(
                  valueListenable: session.toolModeNotifier,
                  builder: (context, currentMode, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < tools.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _buildToolButton(
                            icon: tools[i].icon,
                            label: tools[i].label,
                            isActive: currentMode == tools[i].mode,
                            onPressed: () => session.toolModeNotifier.value = tools[i].mode,
                            theme: theme,
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
                    _buildActionButton(
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

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required ThemeData theme,
    required Color primaryColor,
    required Color textColor,
  }) {
    final activeColor = primaryColor;
    final inactiveColor = textColor.withValues(alpha: 0.7);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: _isCompact ? 8 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 18,
            ),
            if (!_isCompact) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color textColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: textColor.withValues(alpha: 0.7), size: 18),
        onPressed: onPressed,
        splashRadius: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
