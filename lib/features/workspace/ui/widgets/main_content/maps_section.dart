import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'recent_section.dart';
import 'projects_section.dart';
import 'templates_section.dart';

class MapsSection extends StatefulWidget {
  const MapsSection({super.key});

  @override
  State<MapsSection> createState() => _MapsSectionState();
}

class _MapsSectionState extends State<MapsSection> {
  final Set<String> _selectedPaths = {};
  final GlobalKey<RecentSectionState> _recentKey = GlobalKey();
  final GlobalKey<ProjectsSectionState> _projectsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    MapManager.instance.addListener(_onMapsChanged);
  }

  @override
  void dispose() {
    MapManager.instance.removeListener(_onMapsChanged);
    super.dispose();
  }

  void _onMapsChanged() {
    if (!mounted) return;
    _recentKey.currentState?.reload();
    _projectsKey.currentState?.reload();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _recentKey.currentState?.reload();
      _projectsKey.currentState?.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecentSection(
          key: _recentKey,
          selectedPaths: _selectedPaths,
          onSelectionChanged: (newSelection) {
            if (!mounted) return;
            setState(() {
              _selectedPaths.clear();
              _selectedPaths.addAll(newSelection);
            });
          },
          onMapsChanged: _onMapsChanged,
        ),
        ProjectsSection(
          key: _projectsKey,
          selectedPaths: _selectedPaths,
          onSelectionChanged: (newSelection) {
            if (!mounted) return;
            setState(() {
              _selectedPaths.clear();
              _selectedPaths.addAll(newSelection);
            });
          },
          onMapsChanged: _onMapsChanged,
        ),
        const TemplatesSection(),
      ],
    );
  }
}
