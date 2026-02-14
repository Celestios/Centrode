import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/graph_controller.dart';
import 'canvas/graph_canvas.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GraphController>();

    return Scaffold(
      appBar: AppBar(
        // Remove branding title
        title: null,
        actions: [
          if (controller.isLoading) const CircularProgressIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadGraph,
          ),
        ],
      ),
      body: const GraphCanvas(),
    );
  }
}