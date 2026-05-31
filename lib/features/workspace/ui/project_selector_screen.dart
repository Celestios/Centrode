import 'package:flutter/material.dart';
import '../../../../presentation/widgets/window_title_bar.dart';
import '../../graph/ui/graph_screen.dart';
import 'liquid_glass_test_screen.dart';

class ProjectSelectorScreen extends StatelessWidget {
  const ProjectSelectorScreen({super.key});

  void _openDefaultGraph(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GraphScreen(storagePath: 'maps/mycelium.db'),
      ),
    );
  }

  void _openLiquidGlassDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LiquidGlassDemo(),
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _openLiquidGlassDemo(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Liquid Glass Demo'),
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

