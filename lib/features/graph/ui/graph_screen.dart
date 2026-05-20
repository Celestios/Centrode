import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import '../presentation/theme_manager.dart';
import '../store/graph_data_controller.dart';
import '../presentation/node_render_state.dart';
import '../presentation/workspace_tabs_controller.dart';
import '../store/graph_data_query.dart';
import 'canvas/graph_canvas.dart';
import 'widgets/init_error_widget.dart';

class GraphScreen extends StatefulWidget {
  final String storagePath;
  const GraphScreen({super.key, required this.storagePath});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  late final WorkspaceTabsController _tabsController;

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
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WorkspaceTabsController>.value(
      value: _tabsController,
      child: Consumer<WorkspaceTabsController>(
        builder: (context, tabsController, _) {
          final activeSession = tabsController.activeSession;
          return ActiveSessionWidget(
            key: ValueKey(activeSession.id),
            session: activeSession,
          );
        },
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
    _initFuture = widget.session.initialize(Theme.of(context));
  }

  @override
  void didUpdateWidget(ActiveSessionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      _initFuture = widget.session.initialize(Theme.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InitErrorWidget(
            error: snapshot.error!,
            onRetry: () {
              setState(() {
                _initFuture = widget.session.initialize(Theme.of(context));
              });
            },
            onShowDetails: () {
              _log.severe('Init error: ${snapshot.error}');
            },
          );
        }

        if (snapshot.connectionState != ConnectionState.done || !widget.session.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return MultiProvider(
          key: ValueKey(widget.session.id), // Reconstruct providers and context hierarchy
          providers: [
            Provider<AppHandle>.value(value: widget.session.handle!),
            ChangeNotifierProvider<ThemeController>.value(
              value: widget.session.themeController!,
            ),
            ChangeNotifierProvider<GraphDataController>.value(
              value: widget.session.dataController!,
            ),
            ListenableProvider<GraphDataQuery>.value(value: widget.session.dataController!),
            ChangeNotifierProvider<NodeRenderState>.value(
              value: widget.session.nodeRenderState!,
            ),
          ],
          child: Consumer<ThemeController>(
            builder: (context, themeController, _) {
              final mapTheme = themeController.currentGraphTheme;
              return Theme(
                data: mapTheme?.toThemeData() ?? Theme.of(context),
                child: const Material(
                  child: GraphCanvas(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
