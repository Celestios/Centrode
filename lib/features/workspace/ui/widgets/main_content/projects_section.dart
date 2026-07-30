import 'package:flutter/material.dart';
import 'package:mycelium/shared/utils/map_scanner.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  List<MapInfo> _projectMaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjectMaps();
  }

  Future<void> _loadProjectMaps() async {
    final maps = await MapScanner.getProjectMaps();
    if (mounted) {
      setState(() {
        _projectMaps = maps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'PROJECTS'),
          SizedBox(height: 48),
        ],
      );
    }

    if (_projectMaps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'PROJECTS'),
        HorizontalScrollRow(
          children: _projectMaps.map((map) {
            final timeAgo = _formatTimeAgo(map.createdAt);
            return ProjectCard(
              name: map.name,
              lastOpened: timeAgo,
              onTap: () {
                // TODO: Open map
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
