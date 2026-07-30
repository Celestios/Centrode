import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'widgets/left_panel/left_panel.dart';
import 'widgets/main_content/main_content_area.dart';
import 'widgets/window_controls.dart';

class WorkspaceHubScreen extends StatelessWidget {
  const WorkspaceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: isDesktop
                ? DragToMoveArea(child: _buildContent(context))
                : _buildContent(context),
          ),
          if (isDesktop) const PositionedWindowControls(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
        const LeftPanel(),
        const Expanded(child: MainContentArea()),
      ],
    );
  }
}
