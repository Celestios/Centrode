import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import '../../features/graph/store/graph_data_controller.dart';
import '../../features/graph/presentation/viewport_state.dart';
import '../../src/rust/domain/base_models.dart' show BoundingBox;

class SearchCommandPalette extends StatefulWidget {
  const SearchCommandPalette({super.key});

  @override
  State<SearchCommandPalette> createState() => _SearchCommandPaletteState();
}

class _SearchCommandPaletteState extends State<SearchCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  List<SearchItem> _results = [];
  int _selectedIndex = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
      _doSearch();
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _doSearch();
    });
  }

  void _doSearch() {
    if (!mounted) return;
    final query = _searchController.text.trim().toLowerCase();
    
    // Get context providers safely
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final GraphDataController? dataController = session.dataController;
    final ViewportController? viewportController = session.viewportController;

    if (dataController == null) return;

    final allItems = <SearchItem>[];

    // 1. Load active nodes
    for (final node in dataController.nodesIterable) {
      if (node.text.toLowerCase().contains(query)) {
        allItems.add(SearchItem(
          title: node.text.isEmpty ? 'Untitled Node' : node.text,
          subtitle: 'Node • ${node.tableName == 'INode' ? 'Info' : 'Task'}',
          icon: node.tableName == 'INode' ? Icons.description_outlined : Icons.task_alt_outlined,
          onSelected: (ctx) {
            if (viewportController != null) {
              final bounds = BoundingBox(
                minX: node.position.dx - 150,
                minY: node.position.dy - 150,
                maxX: node.position.dx + node.size.width + 150,
                maxY: node.position.dy + node.size.height + 150,
              );
              viewportController.focusOnBounds(bounds);
            }
          },
        ));
      }
    }

    // 2. Load commands
    final commands = [
      SearchItem(
        title: 'Toggle Left Panel',
        subtitle: 'Command',
        icon: Icons.menu_open_rounded,
        onSelected: (ctx) {
          session.showLeftPanel.value = !session.showLeftPanel.value;
        },
      ),
      SearchItem(
        title: 'Toggle Right Panel',
        subtitle: 'Command',
        icon: Icons.chrome_reader_mode_outlined,
        onSelected: (ctx) {
          session.showRightPanel.value = !session.showRightPanel.value;
        },
      ),
      SearchItem(
        title: 'Toggle Bottom Panel',
        subtitle: 'Command',
        icon: Icons.call_to_action_outlined,
        onSelected: (ctx) {
          session.showBottomPanel.value = !session.showBottomPanel.value;
        },
      ),
      SearchItem(
        title: 'Undo last action',
        subtitle: 'Command',
        icon: Icons.undo_rounded,
        onSelected: (ctx) => dataController.undo(),
      ),
      SearchItem(
        title: 'Redo action',
        subtitle: 'Command',
        icon: Icons.redo_rounded,
        onSelected: (ctx) => dataController.redo(),
      ),
      SearchItem(
        title: 'Zoom to Fit Map Boundaries',
        subtitle: 'Command',
        icon: Icons.zoom_out_map_rounded,
        onSelected: (ctx) {
          if (viewportController != null) {
            viewportController.focusOnBounds(dataController.canvasBounds.value);
          }
        },
      ),
    ];

    for (final cmd in commands) {
      if (cmd.title.toLowerCase().contains(query)) {
        allItems.add(cmd);
      }
    }

    setState(() {
      _results = allItems;
      _selectedIndex = _selectedIndex.clamp(0, _results.isEmpty ? 0 : _results.length - 1);
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        
        return Positioned(
          width: 500,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-100, 36),
            child: TapRegion(
              groupId: 'search_palette_group',
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: theme.cardColor.withValues(alpha: 0.95),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No matching nodes or commands found.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                final isSelected = index == _selectedIndex;

                                return InkWell(
                                  onTap: () => _selectItem(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    color: isSelected
                                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 18,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.iconTheme.color?.withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.title,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              Text(
                                                item.subtitle,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.hintColor,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Text(
                                            'Enter',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(SearchItem item) {
    item.onSelected(context);
    _searchController.clear();
    _focusNode.unfocus();
    _hideOverlay();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    final itemHeight = 40.0; // approximate height of list item
    final viewportHeight = 300.0;
    final targetOffset = index * itemHeight;
    final currentScroll = _scrollController.offset;

    if (targetOffset < currentScroll) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (targetOffset + itemHeight > currentScroll + viewportHeight) {
      _scrollController.animateTo(
        targetOffset + itemHeight - viewportHeight,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_results.isNotEmpty) {
            _selectedIndex = (_selectedIndex + 1) % _results.length;
            _scrollToIndex(_selectedIndex);
          }
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_results.isNotEmpty) {
            _selectedIndex = (_selectedIndex - 1 + _results.length) % _results.length;
            _scrollToIndex(_selectedIndex);
          }
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_results.isNotEmpty && _selectedIndex < _results.length) {
          _selectItem(_results[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _focusNode.unfocus();
        _hideOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TapRegion(
          groupId: 'search_palette_group',
          onTapOutside: (event) {
            _focusNode.unfocus();
            _hideOverlay();
          },
          child: Container(
            width: 300,
            height: 32,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: theme.iconTheme.color?.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search nodes, commands...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ctrl P',
                    style: TextStyle(
                      fontSize: 8,
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context) onSelected;

  const SearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
  });
}
