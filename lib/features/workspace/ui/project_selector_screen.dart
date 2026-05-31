import 'package:flutter/material.dart';
import '../../../../presentation/widgets/window_title_bar.dart';
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
      body: Column(
        children: [
          const SimpleWindowTitleBar(title: 'Mycelium - Choose Project'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _openDefaultGraph(context),
                    child: const Text('Open Default Graph'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

