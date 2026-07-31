import 'package:flutter/material.dart';
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/shared/utils/recent_maps_store.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
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
                description: 'Maps you open will appear here for quick access.',
              ),
            ],
          )
        else
          HorizontalScrollRow(
            children: _recentMaps.map((map) {
              final timeAgo = _formatTimeAgo(map.lastAccessed);
              return ProjectCard(
                name: map.name,
                lastOpened: timeAgo,
                onTap: () {
                  MapManager.instance.openMap(map.path, map.name);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GraphScreen()),
                  );
                },
                onRename: (newName) async {
                  final oldPath = map.path;
                  final newPath = p.join(
                    await AppPaths.mapsDirectory,
                    '$newName.db',
                  );
                  final wasOpen = MapManager.instance.isPathOpen(oldPath);
                  if (wasOpen) {
                    await MapManager.instance.closeByPath(oldPath);
                  }
                  await AppPaths.renameMapStorage(oldPath, newPath);
                  await RecentMapsStore.rename(oldPath, newPath);
                  if (wasOpen) {
                    MapManager.instance.openMap(newPath, newName);
                  }
                  _loadRecentMaps();
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete map'),
                      content: Text('Delete "${map.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await MapManager.instance.closeByPath(map.path);
                    await AppPaths.deleteMapStorage(map.path);
                    await RecentMapsStore.remove(map.path);
                    _loadRecentMaps();
                  }
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
