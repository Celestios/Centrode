import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/graph_data_controller.dart';
import 'canvas/graph_canvas.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the loadGraph call until after the first frame
    // to ensure the Provider context is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GraphDataController>().loadGraph();
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
            onPressed: () => context.read<GraphDataController>().loadGraph(),
          ),
        ],
      ),
      body: const GraphCanvas(),
    );
  }
}
