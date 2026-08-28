import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'search_registry.dart';
import 'search_overlay_widget.dart';

class SearchCommandPalette extends StatefulWidget {
  final SearchRegistry? searchRegistry;
  final ValueNotifier<bool>? focusNotifier;

  const SearchCommandPalette({super.key, this.searchRegistry, this.focusNotifier});

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

  SearchRegistry get _searchRegistry =>
      widget.searchRegistry ?? SearchRegistry.instance;

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
    widget.focusNotifier?.value = _focusNode.hasFocus;
    if (_focusNode.hasFocus) {
      _showOverlay();
      _doSearch();
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(UiMotion.fast, () {
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

    final isDbSearch = query.startsWith('?');
    if (isDbSearch) {
      setState(() {
        _isLoading = true;
      });
      _overlayEntry?.markNeedsBuild();
    }

    final results = await _searchRegistry.search(query, context);

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

    GraphDataQueryController? queryController;
    try {
      final tabsController = context.read<WorkspaceTabsController>();
      queryController = tabsController.activeSession.queryController;
    } catch (_) {}

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        if (_searchController.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-40, 32),
          child: TapRegion(
            groupId: 'search_palette_group',
            child: SearchOverlayWidget(
              results: _results,
              selectedIndex: _selectedIndex,
              isLoading: _isLoading,
              onSelected: _selectItem,
              scrollController: _scrollController,
              queryController: queryController,
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
    final itemHeight = 40.0;
    final viewportHeight = 300.0;
    final targetOffset = index * itemHeight;
    final currentScroll = _scrollController.offset;

    if (targetOffset < currentScroll) {
      _scrollController.animateTo(
        targetOffset,
        duration: UiMotion.fast,
        curve: Curves.easeOut,
      );
    } else if (targetOffset + itemHeight > currentScroll + viewportHeight) {
      _scrollController.animateTo(
        targetOffset + itemHeight - viewportHeight,
        duration: UiMotion.fast,
        curve: Curves.easeOut,
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_results.isNotEmpty) {
            final hasSelectable = _results.any(
              (r) => r.type != SearchResultType.relationHeader,
            );
            if (hasSelectable) {
              int attempts = 0;
              do {
                _selectedIndex = (_selectedIndex + 1) % _results.length;
                attempts++;
              } while (_results[_selectedIndex].type ==
                      SearchResultType.relationHeader &&
                  attempts < _results.length);
              _scrollToIndex(_selectedIndex);
            }
          }
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_results.isNotEmpty) {
            final hasSelectable = _results.any(
              (r) => r.type != SearchResultType.relationHeader,
            );
            if (hasSelectable) {
              int attempts = 0;
              do {
                _selectedIndex =
                    (_selectedIndex - 1 + _results.length) % _results.length;
                attempts++;
              } while (_results[_selectedIndex].type ==
                      SearchResultType.relationHeader &&
                  attempts < _results.length);
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
    final hasFocus = _focusNode.hasFocus;

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
            child: GlassPanel(
              borderRadius: 8,
              blur: 10.0,
              duration: UiMotion.standard,
              curve: hasFocus ? Curves.fastOutSlowIn : Curves.easeOutCubic,
              width: hasFocus ? 420.0 : 240.0,
              height: UiControlSize.dense,
              color: hasFocus
                  ? theme.cardColor.withValues(alpha: 0.85)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              shadow: hasFocus
                  ? BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  : null,
              border: hasFocus
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      width: UiStrokeWidth.standard,
                    )
                  : null,
              child: Row(
                  children: [
                    const SizedBox(width: UiSpacing.standard),
                    Icon(
                      Icons.search_rounded,
                      size: UiIconSize.dense,
                      color: hasFocus
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color?.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: UiFont.standard),
                        decoration: InputDecoration(
                          hintText: "Search ('>' cmd, '#' tag, '?' db)...",
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor.withValues(alpha: 0.7),
                            fontSize: UiFont.standard,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (hasFocus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(UiRadius.control),
                        ),
                        child: Text(
                          'Ctrl P',
                          style: TextStyle(
                            fontSize: UiFont.micro,
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
}
