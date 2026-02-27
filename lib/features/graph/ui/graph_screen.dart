import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../state/graph_data_controller.dart';
import '../state/graph_ui_controller.dart';
import 'canvas/graph_canvas.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final Logger _log = Logger('GraphScreen');

  Future<void> _loadGraph() async {
    final dataController = context.read<GraphDataController>();
    final uiController = context.read<GraphUIController>();
    await dataController.loadGraph();
    // Sync Z-Order after graph load to restore hit-testing
    uiController.syncZOrder(dataController.nodeLookup.keys);
  }

  @override
  void initState() {
    super.initState();
    _log.info('GraphScreen mounted; deferring loadGraph.');
    // Defer the loadGraph call until after the first frame
    // to ensure the Provider context is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGraph();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GraphDataController>();

    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: [
          if (controller.isLoading) const CircularProgressIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _log.info('User initiated manual graph refresh.');
              _loadGraph();
            },
          ),
        ],
      ),
      body: const GraphCanvas(),
    );
  }
}
