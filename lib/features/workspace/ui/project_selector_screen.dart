import 'package:flutter/material.dart';
import '../../graph/ui/graph_screen.dart';

class ProjectSelectorScreen extends StatelessWidget {
  const ProjectSelectorScreen({super.key});

  void _openDefaultGraph(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GraphScreen(storagePath: 'maps/mycelium.db'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Project')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _openDefaultGraph(context),
          child: const Text('Open Default Graph'),
        ),
      ),
    );
  }
}
