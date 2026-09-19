import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'widgets/left_panel/left_panel.dart';
import 'widgets/main_content/main_content_area.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';

class WorkspaceHubScreen extends StatefulWidget {
  const WorkspaceHubScreen({super.key});

  @override
  State<WorkspaceHubScreen> createState() => _WorkspaceHubScreenState();
}

class _WorkspaceHubScreenState extends State<WorkspaceHubScreen> {
  late final WorkspaceHubController _hubController;

  @override
  void initState() {
    super.initState();
    _hubController = WorkspaceHubController();
  }

  @override
  void dispose() {
    _hubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final isAndroid = !kIsWeb && Platform.isAndroid;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isAndroid ? Drawer(child: SafeArea(child: LeftPanel(controller: _hubController))) : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildContent(context, isAndroid),
          ),
          if (isDesktop)
            const Positioned(
              top: 0,
              left: WorkspaceTokens.leftPanelWidth,
              right: 0,
              child: CentrodeWindowTitleBar(
                title: 'Workspace Hub',
                height: WorkspaceTokens.topBarHeight,
                enableGlass: false,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isAndroid) {
    if (isAndroid) {
      return const MainContentArea();
    }
    return Stack(
      children: [
        const Positioned(
          top: 0,
          bottom: 0,
          left: WorkspaceTokens.leftPanelWidth,
          right: 0,
          child: MainContentArea(),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: WorkspaceTokens.leftPanelWidth,
          child: LeftPanel(controller: _hubController),
        ),
      ],
    );
  }
}
