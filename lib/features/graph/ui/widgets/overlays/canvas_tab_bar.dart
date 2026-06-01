import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import '../../../presentation/workspace_tabs_controller.dart';

class CanvasTabBar extends StatelessWidget {
  const CanvasTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final tabs = tabsController.tabs;
    final activeIndex = tabsController.activeIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassGroup(
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
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
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
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final activeColor = onSurface;
    final inactiveColor = onSurface.withValues(alpha: 0.6);

    final tabDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: widget.isActive
          ? LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.22),
                primaryColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : (_isHovered
              ? LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.14),
                    primaryColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    theme.cardColor.withValues(alpha: 0.65),
                    theme.cardColor.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )),
      border: Border.all(
        color: widget.isActive
            ? primaryColor.withValues(alpha: 0.4)
            : (_isHovered
                ? primaryColor.withValues(alpha: 0.25)
                : theme.dividerColor.withValues(alpha: 0.25)),
        width: 1.0,
      ),
      boxShadow: widget.isActive
          ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
          : (_isHovered
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null),
    );

    double scale = 1.0;
    if (_isHovered) scale = 1.04;
    if (_isPressed) scale = 0.96;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: GlassPanel(
          borderRadius: 10,
          color: theme.cardColor.withValues(alpha: 0.55),
          shadow: widget.isActive
              ? BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: tabDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (highlighted) =>
                    setState(() => _isPressed = highlighted),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: widget.isActive ? activeColor : (_isHovered ? primaryColor : inactiveColor),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                          color: widget.isActive ? activeColor : (_isHovered ? primaryColor : inactiveColor),
                        ),
                      ),
                      if (widget.canClose) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Icon(
                            Icons.close_rounded,
                            color: widget.isActive
                                ? activeColor.withValues(alpha: 0.6)
                                : (_isHovered ? primaryColor.withValues(alpha: 0.6) : inactiveColor.withValues(alpha: 0.6)),
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTabButton extends StatefulWidget {
  final WorkspaceTabsController tabsController;

  const _AddTabButton({required this.tabsController});

  @override
  State<_AddTabButton> createState() => _AddTabButtonState();
}

class _AddTabButtonState extends State<_AddTabButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final addDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: _isHovered
          ? LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.18),
                primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                theme.cardColor.withValues(alpha: 0.55),
                theme.cardColor.withValues(alpha: 0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      border: Border.all(
        color: _isHovered
            ? primaryColor.withValues(alpha: 0.3)
            : theme.dividerColor.withValues(alpha: 0.25),
        width: 1.0,
      ),
      boxShadow: _isHovered
          ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ]
          : null,
    );

    double scale = 1.0;
    if (_isHovered) scale = 1.05;
    if (_isPressed) scale = 0.95;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: GlassPanel(
          borderRadius: 10,
          color: theme.cardColor.withValues(alpha: 0.55),
          shadow: _isHovered
              ? BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: addDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final newIndex = widget.tabsController.tabs.length + 1;
                  widget.tabsController.addTab(
                    'maps/mycelium_tab_$newIndex.db',
                    'Map $newIndex',
                  );
                },
                onHighlightChanged: (highlighted) =>
                    setState(() => _isPressed = highlighted),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(
                    Icons.add_rounded,
                    color: _isHovered
                        ? primaryColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
