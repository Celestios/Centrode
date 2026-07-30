import 'package:flutter/material.dart';
import 'package:mycelium/presentation/widgets/window_title_bar.dart';
import 'widgets/left_panel/left_panel.dart';
import 'widgets/main_content/main_content_area.dart';

class WorkspaceHubScreen extends StatelessWidget {
  const WorkspaceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SimpleWindowTitleBar(title: 'Mycelium - Workspace Hub'),
          Expanded(
            child: Row(
              children: [
                const LeftPanel(),
                const Expanded(child: MainContentArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
