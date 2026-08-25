import 'package:flutter/material.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';
import 'map_section.dart';

class ProjectsSection extends StatefulWidget {
  final Set<String> selectedPaths;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onMapsChanged;
  final WorkspaceHubController? controller;

  const ProjectsSection({
    super.key,
    required this.selectedPaths,
    required this.onSelectionChanged,
    this.onMapsChanged,
    this.controller,
  });

  @override
  State<ProjectsSection> createState() => ProjectsSectionState();
}

class ProjectsSectionState extends State<ProjectsSection> {
  final _sectionKey = GlobalKey<MapSectionState>();

  Future<void> reload() async {
    await _sectionKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final hubController = widget.controller ?? WorkspaceHubController();

    return MapSection(
      key: _sectionKey,
      title: 'Projects',
      fetchMaps: hubController.fetchProjectMaps,
      emptyTitle: 'No project maps',
      emptySubtitle: 'Your project maps will appear here',
      selectedPaths: widget.selectedPaths,
      onSelectionChanged: widget.onSelectionChanged,
      onMapsChanged: widget.onMapsChanged,
      controller: hubController,
    );
  }
}
