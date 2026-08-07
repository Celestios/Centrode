import 'package:flutter/material.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'map_section.dart';

class ProjectsSection extends StatefulWidget {
  final Set<String> selectedPaths;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onMapsChanged;

  const ProjectsSection({
    super.key,
    required this.selectedPaths,
    required this.onSelectionChanged,
    this.onMapsChanged,
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
    return MapSection(
      key: _sectionKey,
      title: 'Projects',
      fetchMaps: MapScanner.getProjectMaps,
      emptyTitle: 'No project maps',
      emptySubtitle: 'Your project maps will appear here',
      selectedPaths: widget.selectedPaths,
      onSelectionChanged: widget.onSelectionChanged,
      onMapsChanged: widget.onMapsChanged,
    );
  }
}
