import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import '../../features/graph/store/graph_data_controller.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'search_command_palette.dart';

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
      child: Row(
        children: [
          // Drag area
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const WindowControlButtons(),
        ],
      ),
    );
  }
}

class WorkspaceWindowTitleBar extends StatelessWidget {
  const WorkspaceWindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final GraphDataController? dataController = session.dataController;

    final menuButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      padding: WidgetStateProperty.all(
        const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 14),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
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
      child: Row(
        children: [
          // Logo & Standard Menu Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'MYCELIUM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: Theme(
                    data: theme.copyWith(
                      hoverColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
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
                          style: menuButtonStyle,
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pop(); // Go back to Project Selection
                              },
                              leadingIcon: const Icon(
                                Icons.folder_open_outlined,
                                size: 16,
                              ),
                              child: const Text('Open Project Selector'),
                            ),
                            MenuItemButton(
                              onPressed: () {
                                if (dataController != null) {
                                  dataController.flushSync();
                                }
                              },
                              leadingIcon: const Icon(
                                Icons.save_outlined,
                                size: 16,
                              ),
                              child: const Text('Force Sync Save'),
                            ),
                          ],
                          child: const Text(
                            'File',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SubmenuButton(
                          style: menuButtonStyle,
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {
                                session.showLeftPanel.value =
                                    !session.showLeftPanel.value;
                              },
                              leadingIcon: const Icon(
                                Icons.menu_open_rounded,
                                size: 16,
                              ),
                              child: const Text('Toggle Left Sidebar'),
                            ),
                            MenuItemButton(
                              onPressed: () {
                                session.showRightPanel.value =
                                    !session.showRightPanel.value;
                              },
                              leadingIcon: const Icon(
                                Icons.chrome_reader_mode_outlined,
                                size: 16,
                              ),
                              child: const Text('Toggle Right Inspector'),
                            ),
                            MenuItemButton(
                              onPressed: () {
                                session.showBottomPanel.value =
                                    !session.showBottomPanel.value;
                              },
                              leadingIcon: const Icon(
                                Icons.call_to_action_outlined,
                                size: 16,
                              ),
                              child: const Text('Toggle Status Bar'),
                            ),
                          ],
                          child: const Text(
                            'View',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SubmenuButton(
                          style: menuButtonStyle,
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () async {
                                final isMaximized = await windowManager
                                    .isMaximized();
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
                          style: menuButtonStyle,
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Mycelium',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: Icon(
                                    Icons.hub_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 36,
                                  ),
                                  children: const [
                                    Text(
                                      'Mycelium is a fast Labeled Property Graph Editor designed in Flutter, powered by SurrealDB and Rust.',
                                    ),
                                  ],
                                );
                              },
                              leadingIcon: const Icon(
                                Icons.info_outline,
                                size: 16,
                              ),
                              child: const Text('About Mycelium'),
                            ),
                          ],
                          child: const Text(
                            'Help',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Central Drag Area with Search Bar in the middle
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const DragToMoveArea(
                  child: SizedBox.expand(),
                ),
                const SearchCommandPalette(),
              ],
            ),
          ),

          // Layout Toggles & Native Control Buttons
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize
        _buildHoverButton(
          icon: Icons.minimize_rounded,
          color: color,
          hoverColor: Colors.grey.withValues(alpha: 0.2),
          onPressed: () => windowManager.minimize(),
        ),
        // Maximize/Restore
        _buildHoverButton(
          icon: _isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          color: color,
          hoverColor: Colors.grey.withValues(alpha: 0.2),
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            _checkMaximizeState();
          },
        ),
        // Close
        _buildHoverButton(
          icon: Icons.close_rounded,
          color: color,
          hoverColor: Colors.red.withValues(alpha: 0.8),
          hoverIconColor: Colors.white,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }

  Widget _buildHoverButton({
    required IconData icon,
    required Color color,
    required Color hoverColor,
    Color? hoverIconColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: HoverBuilder(
              hoverColor: hoverColor,
              builder: (context, isHovered) {
                return Container(
                  width: 42,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 16,
                    color: isHovered ? (hoverIconColor ?? color) : color,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HoverBuilder extends StatefulWidget {
  final Color hoverColor;
  final Widget Function(BuildContext context, bool isHovered) builder;

  const HoverBuilder({
    super.key,
    required this.hoverColor,
    required this.builder,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.builder(context, _isHovered),
      ),
    );
  }
}
