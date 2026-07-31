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
  final Set<String> _selectedPaths = {};
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

  Future<void> _deleteMaps(List<MapInfo> mapsToDelete) async {
    if (mapsToDelete.isEmpty) return;

    final isPlural = mapsToDelete.length > 1;
    final message = isPlural
        ? 'Delete ${mapsToDelete.length} selected maps?'
        : 'Delete "${mapsToDelete.first.name}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPlural ? 'Delete maps' : 'Delete map'),
        content: Text(message),
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
      for (final map in mapsToDelete) {
        await MapManager.instance.closeByPath(map.path);
        await AppPaths.deleteMapStorage(map.path);
        await RecentMapsStore.remove(map.path);
      }
      if (!mounted) return;
      setState(() {
        _selectedPaths.clear();
      });
      _loadRecentMaps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'RECENT',
          selectedCount: _selectedPaths.length,
          onCancel: () => setState(() => _selectedPaths.clear()),
          onDelete: () {
            final selectedMaps =
                _recentMaps.where((m) => _selectedPaths.contains(m.path)).toList();
            _deleteMaps(selectedMaps);
          },
        ),
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
                isSelected: _selectedPaths.contains(map.path),
                isSelectionMode: _selectedPaths.isNotEmpty,
                onSelectionChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPaths.add(map.path);
                    } else {
                      _selectedPaths.remove(map.path);
                    }
                  });
                },
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
                  if (!mounted) return;
                  _loadRecentMaps();
                },
                onDelete: () => _deleteMaps([map]),
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
