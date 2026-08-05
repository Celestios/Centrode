import 'package:flutter/material.dart';
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/shared/utils/recent_maps_store.dart';
import 'package:path/path.dart' as p;
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';
import 'empty_section_card.dart';

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
  List<MapInfo> _projectMaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final maps = await MapScanner.getProjectMaps();
    if (mounted) {
      setState(() {
        _projectMaps = maps;
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
      final newSelection = Set<String>.from(widget.selectedPaths);
      for (final map in mapsToDelete) {
        await MapManager.instance.closeByPath(map.path);
        await AppPaths.deleteMapStorage(map.path);
        await RecentMapsStore.remove(map.path);
        newSelection.remove(map.path);
      }
      widget.onSelectionChanged(newSelection);
      widget.onMapsChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedInSectionCount =
        _projectMaps.where((m) => widget.selectedPaths.contains(m.path)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'PROJECTS',
          selectedCount: selectedInSectionCount,
          onSelectAll: () {
            final newSelection = Set<String>.from(widget.selectedPaths);
            newSelection.addAll(_projectMaps.map((m) => m.path));
            widget.onSelectionChanged(newSelection);
          },
          onCancel: () => widget.onSelectionChanged({}),
          onDelete: () {
            final selectedMaps = _projectMaps
                .where((m) => widget.selectedPaths.contains(m.path))
                .toList();
            _deleteMaps(selectedMaps);
          },
        ),
        if (_isLoading)
          const SizedBox(height: 48)
        else if (_projectMaps.isEmpty)
          const HorizontalScrollRow(
            children: [
              EmptySectionCard(
                description: 'Your created maps are organized here.',
              ),
            ],
          )
        else
          HorizontalScrollRow(
            children: _projectMaps.map((map) {
              final timeAgo = _formatTimeAgo(map.createdAt);
              return ProjectCard(
                name: map.name,
                lastOpened: timeAgo,
                isSelected: widget.selectedPaths.contains(map.path),
                isSelectionMode: widget.selectedPaths.isNotEmpty,
                onSelectionChanged: (selected) {
                  final newSelection = Set<String>.from(widget.selectedPaths);
                  if (selected) {
                    newSelection.add(map.path);
                  } else {
                    newSelection.remove(map.path);
                  }
                  widget.onSelectionChanged(newSelection);
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
                  if (widget.selectedPaths.contains(oldPath)) {
                    final newSelection = Set<String>.from(widget.selectedPaths);
                    newSelection.remove(oldPath);
                    newSelection.add(newPath);
                    widget.onSelectionChanged(newSelection);
                  }
                  widget.onMapsChanged?.call();
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
