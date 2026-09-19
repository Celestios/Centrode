import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/widgets/context_menu_overlay.dart';
import '../store/graph_data_query_controller.dart';
import '../store/command_queue_processor.dart';
import '../presentation/node_render_state.dart';
import '../presentation/workspace_tabs_controller.dart';
import '../presentation/map_manager.dart';
import '../presentation/theme_manager.dart';
import '../presentation/strategies/node_style_strategy.dart';
import '../store/graph_data_query.dart';
import 'canvas/graph_canvas.dart';
import 'widgets/init_error_widget.dart';
import 'package:centrode/shared/copy_buffer.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/presentation/widgets/search/search_command_palette.dart';
import 'widgets/overlays/undo_redo_buttons.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  late final WorkspaceTabsController _tabsController;
  final CopyBuffer _copyBuffer = CopyBuffer();
  final _searchFocusNotifier = ValueNotifier<bool>(false);
  ThemeData? _lastThemeData;
  bool _isThemeAnimating = false;

  @override
  void initState() {
    super.initState();
    _tabsController = MapManager.instance.tabsController;
    MapManager.instance.onAllTabsClosed = _onAllTabsClosed;
  }

  void _onAllTabsClosed() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    MapManager.instance.onAllTabsClosed = null;
    _copyBuffer.dispose();
    _searchFocusNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    NodeStyleStrategy.setPalette(CentrodeDerivedPalette.of(context));
    return ChangeNotifierProvider<CopyBuffer>.value(
      value: _copyBuffer,
      child: ChangeNotifierProvider<WorkspaceTabsController>.value(
        value: _tabsController,
        child: Consumer<WorkspaceTabsController>(
          builder: (context, tabsController, _) {
            if (tabsController.tabs.isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final activeSession = tabsController.activeSession;

            return ListenableBuilder(
              listenable: Listenable.merge(
                [
                  activeSession,
                  activeSession.themeController,
                ].whereType<Listenable>(),
              ),
              builder: (context, _) {
                final mapTheme =
                    activeSession.themeController.currentGraphTheme;

                final ThemeData themeData;
                if (mapTheme != null) {
                  final newThemeData = mapTheme.toThemeData();
                  final themeChanged =
                      _lastThemeData != null && _lastThemeData != newThemeData;
                  _lastThemeData = newThemeData;
                  themeData = newThemeData;
                  if (themeChanged) {
                    _isThemeAnimating = true;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _isThemeAnimating = false);
                    });
                  }
                } else {
                  themeData = _lastThemeData ?? AppThemeManager.instance.themeNotifier.value.toThemeData();
                }

                final themeWidget = _isThemeAnimating
                    ? AnimatedTheme(
                        data: themeData,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: _buildScaffold(tabsController),
                      )
                    : Theme(
                        data: themeData,
                        child: _buildScaffold(tabsController),
                      );

                return themeWidget;
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(WorkspaceTabsController tabsController) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: tabsController.activeIndex,
              children: tabsController.tabs.map((session) {
                return ActiveSessionWidget(
                  key: ValueKey(session.id),
                  session: session,
                );
              }).toList(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder: (context) {
                final session = tabsController.activeSession;
                final theme = Theme.of(context);
                return CentrodeWindowTitleBar(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            const SizedBox(width: UiSpacing.tight),
                            HoverExpandableMenuBar(
                              sections: [
                                CentrodeMenuSection(
                                  title: 'File',
                                  items: [
                                    CentrodeMenuItem.action(
                                      label: 'Force Sync Save',
                                      leadingIcon: Icons.save_outlined,
                                      shortcut: 'Ctrl+S',
                                      onTap: () {
                                        session.commandProcessor.flushSync();
                                      },
                                    ),
                                  ],
                                ),
                                CentrodeMenuSection(
                                  title: 'View',
                                  items: [
                                    CentrodeMenuItem.action(
                                      label: 'Toggle Left Sidebar',
                                      leadingIcon: Icons.menu_open_rounded,
                                      onTap: () {
                                        session.showLeftPanel.value =
                                            !session.showLeftPanel.value;
                                      },
                                    ),
                                    CentrodeMenuItem.action(
                                      label: 'Toggle Right Inspector',
                                      leadingIcon:
                                          Icons.chrome_reader_mode_outlined,
                                      onTap: () {
                                        session.showRightPanel.value =
                                            !session.showRightPanel.value;
                                      },
                                    ),
                                    CentrodeMenuItem.action(
                                      label: 'Toggle Status Bar',
                                      leadingIcon:
                                          Icons.call_to_action_outlined,
                                      onTap: () {
                                        session.showBottomPanel.value =
                                            !session.showBottomPanel.value;
                                      },
                                    ),
                                  ],
                                ),
                                CentrodeMenuSection(
                                  title: 'Help',
                                  items: [
                                    CentrodeMenuItem.action(
                                      label: 'About Centrode',
                                      leadingIcon: Icons.info_outline,
                                      onTap: () {
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ValueListenableBuilder<bool>(
                      valueListenable: session.showLeftPanel,
                      builder: (context, visible, _) {
                        return CentrodeIconButton(
                          icon: Icons.menu_open_rounded,
                          onPressed: () => session.showLeftPanel.value =
                              !session.showLeftPanel.value,
                          tooltip: 'Toggle Left Panel',
                          iconSize: UiIconSize.standard,
                          buttonSize: 30,
                          enableHover: false,
                          iconColor: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        );
                      },
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    ValueListenableBuilder<bool>(
                      valueListenable: session.showRightPanel,
                      builder: (context, visible, _) {
                        return CentrodeIconButton(
                          icon: Icons.chrome_reader_mode_outlined,
                          onPressed: () => session.showRightPanel.value =
                              !session.showRightPanel.value,
                          tooltip: 'Toggle Right Panel',
                          iconSize: UiIconSize.standard,
                          buttonSize: 30,
                          enableHover: false,
                          iconColor: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        );
                      },
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    ValueListenableBuilder<bool>(
                      valueListenable: session.showBottomPanel,
                      builder: (context, visible, _) {
                        return CentrodeIconButton(
                          icon: Icons.call_to_action_outlined,
                          onPressed: () => session.showBottomPanel.value =
                              !session.showBottomPanel.value,
                          tooltip: 'Toggle Bottom Panel',
                          iconSize: UiIconSize.standard,
                          buttonSize: 30,
                          enableHover: false,
                          iconColor: visible
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.6),
                        );
                      },
                    ),
                    const SizedBox(width: UiSpacing.container),
                  ],
                  stackChildren: [
                    IgnorePointer(
                      ignoring: false,
                      child: Center(
                        child: SearchCommandPalette(
                          focusNotifier: _searchFocusNotifier,
                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveSessionWidget extends StatefulWidget {
  final TabSession session;
  const ActiveSessionWidget({super.key, required this.session});

  @override
  State<ActiveSessionWidget> createState() => _ActiveSessionWidgetState();
}

class _ActiveSessionWidgetState extends State<ActiveSessionWidget> {
  late Future<void> _initFuture;
  final Logger _log = Logger('ActiveSessionWidget');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData globalTheme = AppThemeManager.instance.themeNotifier.value.toThemeData();
    _initFuture = widget.session.initialize(globalTheme);
  }

  @override
  void didUpdateWidget(ActiveSessionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      final ThemeData globalTheme = AppThemeManager.instance.themeNotifier.value.toThemeData();
      _initFuture = widget.session.initialize(globalTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: InitErrorWidget(
              error: snapshot.error!,
              onShowDetails: () {
                _log.severe('Init error: ${snapshot.error}');
              },
            ),
          );
        }

        return MultiProvider(
          key: ValueKey(
            widget.session.id,
          ), // Reconstruct providers and context hierarchy
          providers: [
            ChangeNotifierProvider<ThemeController>.value(
              value: widget.session.themeController,
            ),
            Provider<GraphDataQueryController>.value(
              value: widget.session.queryController,
            ),
            Provider<CommandQueueProcessor>.value(
              value: widget.session.commandProcessor,
            ),
            InheritedProvider<GraphDataQuery>.value(
              value: widget.session.nodeRenderState,
            ),
            ChangeNotifierProvider<NodeRenderState>.value(
              value: widget.session.nodeRenderState,
            ),
          ],
          child: const GraphCanvas(),
        );
      },
    );
  }
}
