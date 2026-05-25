import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search_registry.dart';

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
        _selectedIndex = _selectedIndex.clamp(0, _results.isEmpty ? 0 : _results.length - 1);
      });
      _overlayEntry?.markNeedsBuild();
    }
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
                                _searchController.text.startsWith('?')
                                    ? 'No matching database records found.'
                                    : 'No matching nodes or commands found.',
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
            width: 380,
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
    );
  }
}
