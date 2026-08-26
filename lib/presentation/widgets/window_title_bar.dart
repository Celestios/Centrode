import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'hover_scale_button.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'search/search_command_palette.dart';


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
                    LogoHomeButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 6),
                    HoverExpandableMenuBar(
                      menuBuilder: (context, menuButtonStyle) {
                        return [
                          SubmenuButton(
                            style: menuButtonStyle,
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () {
                                  session.commandProcessor.flushSync();
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
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                          SubmenuButton(
                            style: menuButtonStyle,
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
                            style: menuButtonStyle,
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
                        ];
                      },
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
                      return CentrodeIconButton(
                        icon: Icons.menu_open_rounded,
                        onPressed: () => session.showLeftPanel.value =
                            !session.showLeftPanel.value,
                        tooltip: 'Toggle Left Panel',
                        iconSize: 18,
                        buttonSize: 30,
                        enableHover: false,
                        iconColor: visible
                            ? theme.colorScheme.primary
                            : theme.hintColor.withValues(alpha: 0.6),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showRightPanel,
                    builder: (context, visible, _) {
                      return CentrodeIconButton(
                        icon: Icons.chrome_reader_mode_outlined,
                        onPressed: () => session.showRightPanel.value =
                            !session.showRightPanel.value,
                        tooltip: 'Toggle Right Panel',
                        iconSize: 18,
                        buttonSize: 30,
                        enableHover: false,
                        iconColor: visible
                            ? theme.colorScheme.primary
                            : theme.hintColor.withValues(alpha: 0.6),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showBottomPanel,
                    builder: (context, visible, _) {
                      return CentrodeIconButton(
                        icon: Icons.call_to_action_outlined,
                        onPressed: () => session.showBottomPanel.value =
                            !session.showBottomPanel.value,
                        tooltip: 'Toggle Bottom Panel',
                        iconSize: 18,
                        buttonSize: 30,
                        enableHover: false,
                        iconColor: visible
                            ? theme.colorScheme.primary
                            : theme.hintColor.withValues(alpha: 0.6),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
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
              final offset = isFocused ? -265.0 : -175.0;
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
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
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
                HistoryBadgeButton(
                  icon: Icons.undo_rounded,
                  isEnabled: canUndo,
                  count: undoCount,
                  tooltip: canUndo
                      ? 'Undo ($undoCount actions)'
                      : 'Undo (No actions)',
                  onTap: canUndo ? () => sessionObj.undo() : null,
                  textColor: textColor,
                ),
                const SizedBox(height: 4),
                HistoryBadgeButton(
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
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HistoryBadgeButton(
                icon: Icons.undo_rounded,
                isEnabled: canUndo,
                count: undoCount,
                tooltip: canUndo
                    ? 'Undo ($undoCount actions remaining)'
                    : 'Undo (No actions available)',
                onTap: canUndo ? () => sessionObj.undo() : null,
                textColor: textColor,
              ),
              const SizedBox(width: 3),
              HoverScaleButton(
                onTap: () {},
                tooltip: 'Version Control\n$undoCount undo(s), $redoCount redo(s) available',
                borderRadius: BorderRadius.circular(6),
                hoverScale: 1.05,
                pressScale: 0.95,
                builder: (context, isHovered, _) => Container(
                  padding: const EdgeInsets.all(2),
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
              const SizedBox(width: 3),
              HistoryBadgeButton(
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
