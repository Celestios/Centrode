import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import '../../features/graph/models/graph_node.dart';
import 'search_registry.dart';

class SearchCommandPalette extends StatefulWidget {
  const SearchCommandPalette({super.key});

  @override
  State<SearchCommandPalette> createState() => _SearchCommandPaletteState();
}

class _SearchCommandPaletteState extends State<SearchCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode(skipTraversal: true);
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  List<SearchResult> _results = [];
  int _selectedIndex = 0;
  Timer? _debounceTimer;
  bool _isLoading = false;

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
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
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

  Future<void> _doSearch() async {
    if (!mounted) return;
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _selectedIndex = 0;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    // If it's a database query, show a progress bar immediately
    final isDbSearch = query.startsWith('?');
    if (isDbSearch) {
      setState(() {
        _isLoading = true;
      });
      _overlayEntry?.markNeedsBuild();
    }

    final results = await SearchRegistry.instance.search(query, context);

    // If query was superseded, results will be null.
    if (results == null) return;

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
        
        int firstSelectable = 0;
        for (int i = 0; i < _results.length; i++) {
          if (_results[i].type != SearchResultType.relationHeader) {
            firstSelectable = i;
            break;
          }
        }
        _selectedIndex = firstSelectable;
      });
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(overlayContext);
        final dataController = context.read<WorkspaceTabsController>().activeSession.dataController;

        if (_searchController.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          width: 500,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-80, 36),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isLoading)
                            LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                           if (!_isLoading && _results.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No matching results',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            )
                          else if (_results.isNotEmpty)
                            Flexible(
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  final isSelected = index == _selectedIndex;

                                  if (item.type == SearchResultType.relationHeader) {
                                    return Container(
                                      padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 6),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.relationVerb?.toUpperCase() ?? 'RELATION',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: theme.dividerColor.withValues(alpha: 0.15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (item.type == SearchResultType.relation) {
                                    final rel = item.relation;
                                    final fromNode = rel != null ? dataController?.nodeLookup[rel.fromNodeId] : null;
                                    final toNode = rel != null ? dataController?.nodeLookup[rel.toNodeId] : null;

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
                                              size: 16,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.iconTheme.color?.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 10),
                                            _buildNodePreview(fromNode, theme),
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      height: 1.5,
                                                      color: theme.dividerColor.withValues(alpha: 0.3),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.centerRight,
                                                      child: Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 14,
                                                        color: theme.dividerColor.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            _buildNodePreview(toNode, theme),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'Enter',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }

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
                        ],
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

  void _selectItem(SearchResult item) {
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
            final hasSelectable = _results.any((r) => r.type != SearchResultType.relationHeader);
            if (hasSelectable) {
              int attempts = 0;
              do {
                _selectedIndex = (_selectedIndex + 1) % _results.length;
                attempts++;
              } while (_results[_selectedIndex].type == SearchResultType.relationHeader && attempts < _results.length);
              _scrollToIndex(_selectedIndex);
            }
          }
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_results.isNotEmpty) {
            final hasSelectable = _results.any((r) => r.type != SearchResultType.relationHeader);
            if (hasSelectable) {
              int attempts = 0;
              do {
                _selectedIndex = (_selectedIndex - 1 + _results.length) % _results.length;
                attempts++;
              } while (_results[_selectedIndex].type == SearchResultType.relationHeader && attempts < _results.length);
              _scrollToIndex(_selectedIndex);
            }
          }
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_results.isNotEmpty && _selectedIndex < _results.length) {
          final item = _results[_selectedIndex];
          if (item.type != SearchResultType.relationHeader) {
            _selectItem(item);
          }
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
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TapRegion(
          groupId: 'search_palette_group',
          onTapOutside: (event) {
            _focusNode.unfocus();
            _hideOverlay();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 380,
              height: 32,
              decoration: BoxDecoration(
                color: _focusNode.hasFocus
                    ? theme.cardColor.withValues(alpha: 0.95)
                    : theme.cardColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.15),
                  width: _focusNode.hasFocus ? 1.5 : 1.0,
                ),
                boxShadow: _focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: _focusNode.hasFocus
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color?.withValues(alpha: 0.5),
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
                        hintText: "Search ('>' cmd, '#' tag, '?' db)...",
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
      ),
    );
  }

  Widget _buildNodePreview(UiNode? node, ThemeData theme) {
    if (node == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Unknown',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      );
    }

    final style = node.resolvedStyle;
    final bgColor = style != null ? Color(style.bgColor) : theme.cardColor;
    final strokeColor = style != null ? Color(style.strokeColor) : theme.dividerColor;
    final textColor = style != null ? Color(style.textColor) : theme.textTheme.bodyMedium?.color;
    final borderRadius = style != null ? style.borderRadius : 4.0;
    final isCircle = style?.shape == 'circle';

    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isCircle ? BorderRadius.circular(100) : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: strokeColor,
          width: 1,
        ),
      ),
      child: Text(
        node.text.isEmpty ? 'Untitled Node' : node.text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: style?.fontFamily,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
