import 'package:flutter/material.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'map_section.dart';

class RecentSection extends StatefulWidget {
  final Set<String> selectedPaths;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onMapsChanged;

  const RecentSection({
    super.key,
    required this.selectedPaths,
    required this.onSelectionChanged,
    this.onMapsChanged,
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
    return MapSection(
      key: _sectionKey,
      title: 'Recent maps',
      fetchMaps: MapScanner.getRecentMaps,
      emptyTitle: 'No recent maps',
      emptySubtitle: 'Open or create a map to see it here',
      selectedPaths: widget.selectedPaths,
      onSelectionChanged: widget.onSelectionChanged,
      onMapsChanged: widget.onMapsChanged,
    );
  }
}
