import 'package:flutter/material.dart';
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/infrastructure/lifecycle/daemon_gateway.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';
import 'empty_section_card.dart';

class MapSection extends StatefulWidget {
  final String title;
  final Future<List<MapInfo>> Function() fetchMaps;
  final String emptyTitle;
  final String emptySubtitle;
  final Set<String> selectedPaths;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onMapsChanged;

  const MapSection({
    super.key,
    required this.title,
    required this.fetchMaps,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.selectedPaths,
    required this.onSelectionChanged,
    this.onMapsChanged,
  });

  @override
  State<MapSection> createState() => MapSectionState();
}

class MapSectionState extends State<MapSection> {
  List<MapInfo> _maps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final maps = await widget.fetchMaps();
    if (mounted) {
      setState(() {
        _maps = maps;
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
        await MapManager.instance.closeByPath(map.path, saveState: false);
      }
      for (final map in mapsToDelete) {
        await DaemonGateway.instance.deleteMap(map.id);
        newSelection.remove(map.path);
      }
      if (!mounted) return;
      widget.onSelectionChanged(newSelection);
      widget.onMapsChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedInSectionCount =
        _maps.where((m) => widget.selectedPaths.contains(m.path)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: widget.title,
          selectedCount: selectedInSectionCount,
          onSelectAll: () {
            final newSelection = Set<String>.from(widget.selectedPaths);
            for (final map in _maps) {
              newSelection.add(map.path);
            }
            widget.onSelectionChanged(newSelection);
          },
          onCancel: () {
            widget.onSelectionChanged({});
          },
          onDelete: () {
            final mapsToDelete = _maps
                .where((m) => widget.selectedPaths.contains(m.path))
                .toList();
            _deleteMaps(mapsToDelete);
          },
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_maps.isEmpty)
          HorizontalScrollRow(
            children: [
              EmptySectionCard(
                description: widget.emptySubtitle,
              ),
            ],
          )
        else
          HorizontalScrollRow(
            children: <Widget>[
              for (final map in _maps)
                ProjectCard(
                  name: map.name,
                  lastOpened: _formatTimeAgo(map.lastModified),
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
                    MapManager.instance.openMap(map.path, map.name, mapId: map.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GraphScreen(),
                      ),
                    );
                  },
                  onDelete: () => _deleteMaps([map]),
                  onRename: (newName) async {
                    if (newName == map.name) return;
                    await MapManager.instance.closeByPath(map.path, saveState: true);
                    final updated = await DaemonGateway.instance.renameMap(map.id, newName);
                    if (!mounted) return;
                    if (widget.selectedPaths.contains(map.path)) {
                      final newSelection = Set<String>.from(widget.selectedPaths)
                        ..remove(map.path)
                        ..add(updated.storagePath);
                      widget.onSelectionChanged(newSelection);
                    }
                    widget.onMapsChanged?.call();
                  },
                ),
            ],
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
