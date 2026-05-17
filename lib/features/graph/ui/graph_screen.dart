import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import '../presentation/theme_manager.dart';
import '../store/graph_repository.dart';
import '../state/graph_ui_controller.dart';
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
  final Logger _log = Logger('GraphScreen');

  ThemeController? _themeController;
  GraphDataController? _dataController;
  GraphUIController? _uiController;
  bool _initialized = false;
  late final Future<AppHandle> _handleFuture = _createAppHandle();

  Future<AppHandle> _createAppHandle() async {
    final handle = await AppHandle.newInstance(
      storagePath: widget.storagePath,
      name: 'Default Map',
    );
    _log.info('AppHandle created for ${widget.storagePath}');
    return handle;
  }

  @override
  void dispose() {
    _themeController?.dispose();
    _dataController?.dispose();
    _uiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppHandle>(
      future: _handleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InitErrorWidget(
            error: snapshot.error!,
            onRetry: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      GraphScreen(storagePath: widget.storagePath),
                ),
              );
            },
            onShowDetails: () {
              _log.severe('Init error: ${snapshot.error}');
            },
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final appHandle = snapshot.data!;

        // Create controllers once, schedule init after this frame
        if (!_initialized) {
          _initialized = true; // prevent multiple schedules
          _themeController ??= ThemeController(appHandle);
          _dataController ??= GraphDataController(appHandle, _themeController!);
          _uiController ??= GraphUIController(_dataController!);

          // Defer the async theme load and graph hydration until after the current build cycle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _themeController!.initialize(Theme.of(context));
            _dataController!.loadGraph();
          });
        }

        return MultiProvider(
          providers: [
            Provider<AppHandle>.value(value: appHandle),
            ChangeNotifierProvider<ThemeController>.value(
              value: _themeController!,
            ),
            ChangeNotifierProvider<GraphDataController>.value(
              value: _dataController!,
            ),
            ListenableProvider<GraphDataQuery>.value(value: _dataController!),
            ChangeNotifierProvider<GraphUIController>.value(
              value: _uiController!,
            ),
          ],
          child: Consumer<ThemeController>(
            builder: (context, themeController, _) {
              final mapTheme = themeController.currentGraphTheme;
              return Theme(
                data: mapTheme?.toThemeData() ?? Theme.of(context),
                child: const GraphCanvas(),
              );
            },
          ),
        );
      },
    );
  }
}
