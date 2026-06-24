import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/logging.dart';
import '../../../../presentation/widgets/window_title_bar.dart';
import '../../../../presentation/theme/app_theme_manager.dart';
import '../presentation/theme_manager.dart';
import '../store/graph_data_controller.dart';
import '../presentation/graph_presentation_notifier.dart';
import '../presentation/node_render_state.dart';
import '../presentation/workspace_tabs_controller.dart';
import '../store/graph_data_query.dart';
import 'canvas/graph_canvas.dart';
import 'widgets/init_error_widget.dart';
import 'package:mycelium/shared/copy_buffer.dart';

class GraphScreen extends StatefulWidget {
  final String storagePath;
  const GraphScreen({super.key, required this.storagePath});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  late final WorkspaceTabsController _tabsController;
  final CopyBuffer _copyBuffer = CopyBuffer();
  ThemeData? _lastThemeData;
  bool _isThemeAnimating = false;

  @override
  void initState() {
    super.initState();
    _tabsController = WorkspaceTabsController(
      initialPath: widget.storagePath,
      initialName: 'Default Map',
    );
  }

  @override
  void dispose() {
    _copyBuffer.dispose();
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CopyBuffer>.value(
      value: _copyBuffer,
      child: ChangeNotifierProvider<WorkspaceTabsController>.value(
        value: _tabsController,
        child: Consumer<WorkspaceTabsController>(
          builder: (context, tabsController, _) {
            final activeSession = tabsController.activeSession;

            return ListenableBuilder(
              listenable: Listenable.merge(
                [
                  activeSession,
                  activeSession.themeController,
                ].whereType<Listenable>(),
              ),
              builder: (context, _) {
                final mapTheme = activeSession.themeController?.currentGraphTheme;
                ThemeData fallbackTheme() {
                  try {
                    return AppThemeManager.instance.themeNotifier.value.toThemeData();
                  } catch (_) {
                    return Theme.of(context);
                  }
                }

                final ThemeData themeData;
                if (mapTheme != null) {
                  final newThemeData = mapTheme.toThemeData();
                  final themeChanged = _lastThemeData != null && _lastThemeData != newThemeData;
                  _lastThemeData = newThemeData;
                  themeData = newThemeData;
                  if (themeChanged) {
                    _isThemeAnimating = true;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _isThemeAnimating = false);
                    });
                  }
                } else {
                  themeData = _lastThemeData ?? fallbackTheme();
                }

                final themeWidget = _isThemeAnimating
                    ? AnimatedTheme(
                        data: themeData,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: _buildScaffold(activeSession),
                      )
                    : Theme(
                        data: themeData,
                        child: _buildScaffold(activeSession),
                      );

                return themeWidget;
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(TabSession activeSession) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ActiveSessionWidget(
              key: ValueKey(activeSession.id),
              session: activeSession,
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WorkspaceWindowTitleBar(),
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
    ThemeData globalTheme;
    try {
      globalTheme = AppThemeManager.instance.themeNotifier.value.toThemeData();
    } catch (_) {
      globalTheme = Theme.of(context);
    }
    _initFuture = widget.session.initialize(globalTheme);
  }

  @override
  void didUpdateWidget(ActiveSessionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      ThemeData globalTheme;
      try {
        globalTheme = AppThemeManager.instance.themeNotifier.value.toThemeData();
      } catch (_) {
        globalTheme = Theme.of(context);
      }
      _initFuture = widget.session.initialize(globalTheme);
    }
  }

  Widget _buildSessionContent(BuildContext context) {
    return MultiProvider(
      key: ValueKey(
        widget.session.id,
      ), // Reconstruct providers and context hierarchy
      providers: [
        ChangeNotifierProvider<ThemeController>.value(
          value: widget.session.themeController!,
        ),
        Provider<GraphDataController>.value(
          value: widget.session.dataController!,
        ),
        Provider<GraphPresentationNotifier>.value(
          value: widget.session.presentationNotifier!,
        ),
        InheritedProvider<GraphDataQuery>.value(
          value: widget.session.nodeRenderState!,
        ),
        ChangeNotifierProvider<NodeRenderState>.value(
          value: widget.session.nodeRenderState!,
        ),
      ],
      child: const GraphCanvas(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.isInitialized) {
      return _buildSessionContent(context);
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: InitErrorWidget(
              error: snapshot.error!,
              onRetry: () {
                setState(() {
                  _initFuture = widget.session.initialize(Theme.of(context));
                });
              },
              onShowDetails: () {
                _log.severe('Init error: ${snapshot.error}');
              },
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done ||
            !widget.session.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildSessionContent(context);
      },
    );
  }
}
