import 'package:flutter/material.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';
import 'map_section.dart';

class RecentSection extends StatefulWidget {
  final Set<String> selectedPaths;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onMapsChanged;
  final WorkspaceHubController? controller;

  const RecentSection({
    super.key,
    required this.selectedPaths,
    required this.onSelectionChanged,
    this.onMapsChanged,
    this.controller,
  });

  @override
  State<RecentSection> createState() => RecentSectionState();
}

class RecentSectionState extends State<RecentSection> {
  final _sectionKey = GlobalKey<MapSectionState>();

  Future<void> reload() async {
    await _sectionKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final hubController = widget.controller ?? WorkspaceHubController();

    return MapSection(
      key: _sectionKey,
      title: 'Recent maps',
      fetchMaps: hubController.fetchRecentMaps,
      emptyTitle: 'No recent maps',
      emptySubtitle: 'Open or create a map to see it here',
      selectedPaths: widget.selectedPaths,
      onSelectionChanged: widget.onSelectionChanged,
      onMapsChanged: widget.onMapsChanged,
      controller: hubController,
    );
  }
}
