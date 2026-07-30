import 'package:flutter/material.dart';
import 'package:mycelium/shared/utils/map_scanner.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';
import 'empty_section_card.dart';

class RecentSection extends StatefulWidget {
  const RecentSection({super.key});

  @override
  State<RecentSection> createState() => _RecentSectionState();
}

class _RecentSectionState extends State<RecentSection> {
  List<MapInfo> _recentMaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMaps();
  }

  Future<void> _loadRecentMaps() async {
    final maps = await MapScanner.getRecentMaps();
    if (mounted) {
      setState(() {
        _recentMaps = maps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'RECENT'),
        if (_isLoading)
          const SizedBox(height: 48)
        else if (_recentMaps.isEmpty)
          const HorizontalScrollRow(
            children: [
              EmptySectionCard(
                title: 'RECENT',
                description: 'Maps you open will appear here for quick access.',
              ),
            ],
          )
        else
          HorizontalScrollRow(
            children: _recentMaps.map((map) {
              final timeAgo = _formatTimeAgo(map.lastModified);
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
