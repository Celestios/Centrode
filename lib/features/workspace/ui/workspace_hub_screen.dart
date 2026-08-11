import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'widgets/left_panel/left_panel.dart';
import 'widgets/main_content/main_content_area.dart';
import 'package:centrode/shared/elements/elements.dart';

class WorkspaceHubScreen extends StatelessWidget {
  const WorkspaceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final isAndroid = !kIsWeb && Platform.isAndroid;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.scaffoldBackgroundColor,
      drawer: isAndroid ? const Drawer(child: SafeArea(child: LeftPanel())) : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildContent(context, isAndroid),
          ),
          if (isDesktop)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: DragToMoveArea(child: SizedBox.expand()),
            ),
          if (isDesktop)
            const Positioned(
              top: 8,
              right: 0,
              child: WindowControlButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isAndroid) {
    if (isAndroid) {
      return const MainContentArea();
    }
    return const Row(
      children: [
        LeftPanel(),
        Expanded(child: MainContentArea()),
      ],
    );
  }
}
