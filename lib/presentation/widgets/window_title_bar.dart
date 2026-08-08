import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'hover_scale_button.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'search/search_command_palette.dart';


class SimpleWindowTitleBar extends StatelessWidget {
  final String title;

  const SimpleWindowTitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: 38,
      color: theme.colorScheme.surface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DragToMoveArea(child: const SizedBox.expand()),
          ),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'CENTRODE',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: '  Workspace Hub',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(right: 0, child: WindowControlButtons()),
        ],
      ),
    );
  }
}

class WorkspaceWindowTitleBar extends StatefulWidget {
  const WorkspaceWindowTitleBar({super.key});

  @override
  State<WorkspaceWindowTitleBar> createState() => _WorkspaceWindowTitleBarState();
}

class _WorkspaceWindowTitleBarState extends State<WorkspaceWindowTitleBar> {
  final _searchFocusNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _searchFocusNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;


    final menuButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      padding: WidgetStateProperty.all(
        const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return GlassPanel(
      borderRadius: 0,
      blur: 16.0,
      color: theme.cardColor.withValues(alpha: 0.65),
      height: 40,
      shadow: BoxShadow(
        color: theme.dividerColor.withValues(alpha: 0.2),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // Logo & Standard Menu Options
              Container(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                            ).createShader(bounds),
                            child: CustomPaint(
                              size: const Size(18, 20),
                              painter: _HomePolygonPainter(),
                            ),
                          ),
                          const SizedBox(width: 2),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'CENTRODE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _HoverExpandableMenuBar(
                      session: session,
                      menuButtonStyle: menuButtonStyle,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: const DragToMoveArea(child: SizedBox.expand()),
              ), // Layout Toggles & Native Control Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Panel layout toggles
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showLeftPanel,
                    builder: (context, visible, _) {
                      return IconButton(
                        icon: Icon(
                          Icons.menu_open_rounded,
                          color: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Toggle Left Panel',
                        iconSize: 18,
                        splashRadius: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => session.showLeftPanel.value =
                            !session.showLeftPanel.value,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showRightPanel,
                    builder: (context, visible, _) {
                      return IconButton(
                        icon: Icon(
                          Icons.chrome_reader_mode_outlined,
                          color: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Toggle Right Panel',
                        iconSize: 18,
                        splashRadius: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => session.showRightPanel.value =
                            !session.showRightPanel.value,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showBottomPanel,
                    builder: (context, visible, _) {
                      return IconButton(
                        icon: Icon(
                          Icons.call_to_action_outlined,
                          color: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Toggle Bottom Panel',
                        iconSize: 18,
                        splashRadius: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => session.showBottomPanel.value =
                            !session.showBottomPanel.value,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Separator
                  Container(
                    width: 1,
                    height: 20,
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 4),
                  const WindowControlButtons(),
                ],
              ),
            ],
          ),
          Center(
            child: IgnorePointer(
              ignoring: false,
              child: SearchCommandPalette(focusNotifier: _searchFocusNotifier),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _searchFocusNotifier,
            builder: (context, isFocused, _) {
              final offset = isFocused ? -262.0 : -172.0;
              return Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: UndoRedoButtons(session: session),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WindowControlButtons extends StatefulWidget {
  const WindowControlButtons({super.key});

  @override
  State<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends State<WindowControlButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizeState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = false;
      });
    }
  }

  Future<void> _checkMaximizeState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && _isMaximized != maximized) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color =
        theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimize
          _buildHoverButton(
            icon: Icons.minimize_rounded,
            color: color,
            isDark: isDark,
            onPressed: () => windowManager.minimize(),
          ),
          const SizedBox(width: 4),
          // Maximize/Restore
          _buildHoverButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            color: color,
            isDark: isDark,
            onPressed: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              _checkMaximizeState();
            },
          ),
          const SizedBox(width: 4),
          // Close
          _buildHoverButton(
            icon: Icons.close_rounded,
            color: color,
            isDark: isDark,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isClose = false,
    required VoidCallback onPressed,
  }) {
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final hoverBg = isClose
        ? Colors.red.withValues(alpha: 0.85)
        : (isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.12));

    return HoverScaleButton(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      hoverScale: 1.0,
      pressScale: 1.0,
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHovered ? hoverBg : defaultBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: (isHovered && isClose)
                ? Colors.white
                : color.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}

class _HistoryBadgeButton extends StatefulWidget {
  final IconData icon;
  final bool isEnabled;
  final int count;
  final String tooltip;
  final VoidCallback? onTap;
  final Color textColor;

  const _HistoryBadgeButton({
    required this.icon,
    required this.isEnabled,
    required this.count,
    required this.tooltip,
    required this.onTap,
    required this.textColor,
  });

  @override
  State<_HistoryBadgeButton> createState() => _HistoryBadgeButtonState();
}

class _HistoryBadgeButtonState extends State<_HistoryBadgeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: widget.isEnabled ? (_) => setState(() => _isHovered = true) : null,
        onExit: widget.isEnabled ? (_) => setState(() => _isHovered = false) : null,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: widget.isEnabled && _isHovered
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: widget.isEnabled && _isHovered
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: widget.isEnabled && _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: !widget.isEnabled
                        ? widget.textColor.withValues(alpha: 0.25)
                        : (_isHovered
                            ? theme.colorScheme.primary
                            : widget.textColor.withValues(alpha: 0.85)),
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

class _HomePolygonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.45)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.35, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HomePolygonPainter oldDelegate) => false;
}

class _HoverExpandableMenuBar extends StatefulWidget {
  final TabSession? session;
  final ButtonStyle menuButtonStyle;

  const _HoverExpandableMenuBar({
    required this.session,
    required this.menuButtonStyle,
  });

  @override
  State<_HoverExpandableMenuBar> createState() =>
      _HoverExpandableMenuBarState();
}

class _HoverExpandableMenuBarState extends State<_HoverExpandableMenuBar> {
  bool _isExpanded = false;
  Timer? _closeTimer;

  void _openMenu() {
    _closeTimer?.cancel();
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _scheduleCloseMenu() {
    _closeTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isExpanded) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _closeMenu() {
    _closeTimer?.cancel();
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;

    return TapRegion(
      groupId: 'menu_bar_group',
      onTapOutside: (_) => _closeMenu(),
      child: MouseRegion(
        onEnter: (_) => _openMenu(),
        onExit: (_) => _scheduleCloseMenu(),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
            firstChild: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.menu_rounded,
                size: 18,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            secondChild: SizedBox(
                height: 32,
                child: Theme(
                  data: theme.copyWith(
                    hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: MenuBar(
                    style: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                    ),
                    children: [
                      SubmenuButton(
                        style: widget.menuButtonStyle,
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              session?.commandProcessor?.flushSync();
                            },
                            leadingIcon: const Icon(
                              Icons.save_outlined,
                              size: 16,
                            ),
                            child: const Text('Force Sync Save'),
                          ),
                        ],
                        child: const Text('File', style: TextStyle(fontSize: 12)),
                      ),
                      SubmenuButton(
                        style: widget.menuButtonStyle,
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              if (session != null) {
                                session.showLeftPanel.value =
                                    !session.showLeftPanel.value;
                              }
                            },
                            leadingIcon: const Icon(
                              Icons.menu_open_rounded,
                              size: 16,
                            ),
                            child: const Text('Toggle Left Sidebar'),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              if (session != null) {
                                session.showRightPanel.value =
                                    !session.showRightPanel.value;
                              }
                            },
                            leadingIcon: const Icon(
                              Icons.chrome_reader_mode_outlined,
                              size: 16,
                            ),
                            child: const Text('Toggle Right Inspector'),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              if (session != null) {
                                session.showBottomPanel.value =
                                    !session.showBottomPanel.value;
                              }
                            },
                            leadingIcon: const Icon(
                              Icons.call_to_action_outlined,
                              size: 16,
                            ),
                            child: const Text('Toggle Status Bar'),
                          ),
                        ],
                        child: const Text('View', style: TextStyle(fontSize: 12)),
                      ),
                      SubmenuButton(
                        style: widget.menuButtonStyle,
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () async {
                              final isMaximized =
                                  await windowManager.isMaximized();
                              if (isMaximized) {
                                await windowManager.unmaximize();
                              } else {
                                await windowManager.maximize();
                              }
                            },
                            leadingIcon: const Icon(
                              Icons.crop_square_rounded,
                              size: 16,
                            ),
                            child: const Text('Toggle Maximize'),
                          ),
                          MenuItemButton(
                            onPressed: () async {
                              await windowManager.minimize();
                            },
                            leadingIcon: const Icon(
                              Icons.minimize_rounded,
                              size: 16,
                            ),
                            child: const Text('Minimize Window'),
                          ),
                        ],
                        child: const Text(
                          'Window',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SubmenuButton(
                        style: widget.menuButtonStyle,
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Centrode',
                                applicationVersion: '1.0.0',
                                applicationIcon: Icon(
                                  Icons.hub_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 36,
                                ),
                                children: const [
                                  Text(
                                    'Centrode is a fast Labeled Property Graph Editor designed in Flutter, powered by SurrealDB and Rust.',
                                  ),
                                ],
                              );
                            },
                            leadingIcon: const Icon(
                              Icons.info_outline,
                              size: 16,
                            ),
                            child: const Text('About Centrode'),
                          ),
                        ],
                        child: const Text('Help', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class UndoRedoButtons extends StatelessWidget {
  final TabSession? session;
  final bool isVertical;

  const UndoRedoButtons({
    super.key,
    required this.session,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final sessionObj = session;
    if (sessionObj == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return ListenableBuilder(
      listenable: sessionObj,
      builder: (context, _) {
        final canUndo = sessionObj.canUndo;
        final canRedo = sessionObj.canRedo;
        final undoCount = sessionObj.undoCount;
        final redoCount = sessionObj.redoCount;

        if (isVertical) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HistoryBadgeButton(
                  icon: Icons.undo_rounded,
                  isEnabled: canUndo,
                  count: undoCount,
                  tooltip: canUndo
                      ? 'Undo ($undoCount actions)'
                      : 'Undo (No actions)',
                  onTap: canUndo ? () => sessionObj.undo() : null,
                  textColor: textColor,
                ),
                const SizedBox(height: 6),
                _HistoryBadgeButton(
                  icon: Icons.redo_rounded,
                  isEnabled: canRedo,
                  count: redoCount,
                  tooltip: canRedo
                      ? 'Redo ($redoCount actions)'
                      : 'Redo (No actions)',
                  onTap: canRedo ? () => sessionObj.redo() : null,
                  textColor: textColor,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HistoryBadgeButton(
                icon: Icons.undo_rounded,
                isEnabled: canUndo,
                count: undoCount,
                tooltip: canUndo
                    ? 'Undo ($undoCount actions remaining)'
                    : 'Undo (No actions available)',
                onTap: canUndo ? () => sessionObj.undo() : null,
                textColor: textColor,
              ),
              const SizedBox(width: 4),
              HoverScaleButton(
                onTap: () {},
                tooltip: 'Version Control\n$undoCount undo(s), $redoCount redo(s) available',
                borderRadius: BorderRadius.circular(6),
                hoverScale: 1.05,
                pressScale: 0.95,
                builder: (context, isHovered, _) => Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: (canUndo || canRedo)
                        ? (isHovered
                            ? theme.colorScheme.primary
                            : textColor.withValues(alpha: 0.85))
                        : textColor.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _HistoryBadgeButton(
                icon: Icons.redo_rounded,
                isEnabled: canRedo,
                count: redoCount,
                tooltip: canRedo
                    ? 'Redo ($redoCount actions remaining)'
                    : 'Redo (No actions available)',
                onTap: canRedo ? () => sessionObj.redo() : null,
                textColor: textColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
