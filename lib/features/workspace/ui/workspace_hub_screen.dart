import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'widgets/left_panel/left_panel.dart';
import 'widgets/main_content/main_content_area.dart';
import 'widgets/window_controls.dart';

class WorkspaceHubScreen extends StatefulWidget {
  const WorkspaceHubScreen({super.key});

  @override
  State<WorkspaceHubScreen> createState() => _WorkspaceHubScreenState();
}

class _WorkspaceHubScreenState extends State<WorkspaceHubScreen> {
  int _refreshKey = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route?.isCurrent ?? false) {
      setState(() => _refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildContent(context),
          ),
          if (isDesktop)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: DragToMoveArea(child: SizedBox.expand()),
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
        Expanded(child: MainContentArea(key: ValueKey(_refreshKey))),
      ],
    );
  }
}
