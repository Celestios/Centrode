import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/utils/name_generator.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class CanvasTabBar extends StatelessWidget {
  const CanvasTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final tabs = tabsController.tabs;
    final activeIndex = tabsController.activeIndex;

    return GlassGroup(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tabs.length, (index) {
                  final session = tabs[index];
                  final isActive = index == activeIndex;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabItem(
                      name: session.name,
                      isActive: isActive,
                      canClose: true,
                      onTap: () => tabsController.selectTab(index),
                      onClose: () => tabsController.closeTab(index),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _AddTabButton(tabsController: tabsController),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab item
// -----------------------------------------------------------------------------

class _TabItem extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.name,
    required this.isActive,
    required this.canClose,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final activeColor = onSurface;
    final inactiveColor = onSurface.withValues(alpha: 0.6);

    return HoverScaleButton(
      onTap: onTap,
      hoverScale: 1.04,
      pressScale: 0.96,
      borderRadius: BorderRadius.circular(10),
      builder: (context, isHovered, isPressed) {
        final preset = GlassPresets.tab(context, isActive: isActive);
        return GlassPanel(
          borderRadius: preset.borderRadius ?? 10,
          color: isActive
              ? preset.color
              : (isHovered
                    ? theme.cardColor.withValues(alpha: 0.60)
                    : preset.color),
          shadow: preset.shadow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: isActive
                      ? activeColor
                      : (isHovered ? primaryColor : inactiveColor),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? activeColor
                        : (isHovered ? primaryColor : inactiveColor),
                  ),
                ),
                if (canClose) ...[
                  const SizedBox(width: 8),
                  CentrodeIconButton(
                    icon: Icons.close_rounded,
                    onPressed: onClose,
                    iconSize: 14,
                    buttonSize: 20,
                    iconColor: isActive
                        ? activeColor.withValues(alpha: 0.6)
                        : (isHovered
                              ? primaryColor.withValues(alpha: 0.6)
                              : inactiveColor.withValues(alpha: 0.6)),
                    enableHover: false,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Add tab button
// -----------------------------------------------------------------------------

class _AddTabButton extends StatefulWidget {
  final WorkspaceTabsController tabsController;

  const _AddTabButton({
    required this.tabsController,
  });

  @override
  State<_AddTabButton> createState() => _AddTabButtonState();
}

class _AddTabButtonState extends State<_AddTabButton> {
  static const double _collapsedSize = 28.0;
  static const double _expandedWidth = 200.0;
  static const double _headerHeight = 44.0;
  static const double _itemHeight = 32.0;
  static const int _maxVisibleItems = 6;

  static const _duration = Duration(milliseconds: 250);
  static const _closeDelay = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  Timer? _closeTimer;

  bool _isExpanded = false;
  bool _expandLeft = false;
  String _searchQuery = '';
  List<MapInfo> _recentMaps = [];

  List<MapInfo> get _filteredMaps {
    if (_searchQuery.isEmpty) return _recentMaps;
    final query = _searchQuery.toLowerCase();
    return _recentMaps.where((m) => m.name.toLowerCase().contains(query)).toList();
  }

  double get _expandedHeight {
    final visibleCount = _filteredMaps.length.clamp(0, _maxVisibleItems);
    final listExtra = _filteredMaps.isNotEmpty ? 6.0 : 0.0;
    return _headerHeight + (visibleCount * _itemHeight) + listExtra;
  }

  void _checkExpandDirection() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;
      final spaceOnRight = screenWidth - offset.dx;
      _expandLeft = spaceOnRight < (_expandedWidth + 16.0);
    }
  }

  void _open() {
    _closeTimer?.cancel();
    _closeTimer = null;
    _checkExpandDirection();

    if (_overlayEntry == null) {
      _showOverlay();
    } else if (!_isExpanded) {
      _setExpanded(true);
    }
  }

  void _keepOpen() {
    _closeTimer?.cancel();
    _closeTimer = null;

    if (!_isExpanded) {
      _setExpanded(true);
    }
  }

  void _scheduleClose() {
    _closeTimer?.cancel();

    _closeTimer = Timer(_closeDelay, () {
      if (!mounted) return;

      _setExpanded(false);

      _closeTimer = Timer(_duration, () {
        if (!mounted) return;
        _removeOverlay();
      });
    });
  }

  void _cancelClose() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  Future<void> _loadRecentMaps() async {
    final maps = await MapScanner.getRecentMaps();
    if (!mounted) return;
    setState(() {
      _recentMaps = maps;
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;

    setState(() {
      _isExpanded = value;
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _cancelClose();
    _checkExpandDirection();

    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final alignment = _expandLeft ? Alignment.topRight : Alignment.topLeft;

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: alignment,
          followerAnchor: alignment,
          child: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: alignment,
              child: MouseRegion(
                onEnter: (_) => _keepOpen(),
                onExit: (_) => _scheduleClose(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: _buildAnimatedBox(
                    theme: theme,
                    primaryColor: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    _isExpanded = false;
    _searchQuery = '';
    _searchController.clear();
    _overlayEntry!.markNeedsBuild();

    _loadRecentMaps();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;

      _setExpanded(true);
    });
  }

  void _removeOverlay() {
    _closeTimer?.cancel();
    _closeTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  void _close() {
    _cancelClose();

    if (_overlayEntry == null) {
      return;
    }

    _setExpanded(false);

    _closeTimer = Timer(_duration, () {
      if (!mounted) return;
      _removeOverlay();
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.dispose();
    super.dispose();
  }

  void _createMap() {
    final name = _searchQuery.isNotEmpty
        ? _searchQuery
        : NameGenerator.generate();
    final path = 'maps/$name.db';
    widget.tabsController.addTab(path, name);
    _close();
  }

  void _openMap(MapInfo map) {
    MapManager.instance.openMap(map.path, map.name);
    _close();
  }

  Widget _buildAnimatedBox({
    required ThemeData theme,
    required Color primaryColor,
  }) {
    final toolbarPreset = GlassPresets.toolbar(context);
    final filteredMaps = _filteredMaps;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        _isExpanded ? toolbarPreset.borderRadius! : 10,
      ),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        width: _isExpanded ? _expandedWidth : _collapsedSize,
        height: _isExpanded ? _expandedHeight : _collapsedSize,
        decoration: BoxDecoration(
          color: toolbarPreset.color,
          borderRadius: BorderRadius.circular(
            _isExpanded ? toolbarPreset.borderRadius! : 10,
          ),
          border: Border.all(
            color: _isExpanded
                ? theme.colorScheme.onSurface.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: _isExpanded
              ? [
                  toolbarPreset.shadow!,
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: _expandLeft ? null : 0,
              right: _expandLeft ? 0 : null,
              width: _expandedWidth,
              height: _expandedHeight,
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: _duration,
                curve: _isExpanded
                    ? const Interval(0.0, 0.4, curve: Curves.easeOut)
                    : const Interval(0.7, 1.0, curve: Curves.easeIn),
                child: IgnorePointer(
                  ignoring: !_isExpanded,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search or create...',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  _overlayEntry?.markNeedsBuild();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filteredMaps.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            height: 1,
                            thickness: 0.6,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 4, top: 2),
                            itemCount: filteredMaps.length,
                            itemBuilder: (context, index) {
                              final map = filteredMaps[index];
                              return _RecentMapTile(
                                map: map,
                                onTap: () => _openMap(map),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: _duration,
              curve: _curve,
              top: _isExpanded ? 8 : 0,
              left: _expandLeft ? null : (_isExpanded ? _expandedWidth - 36 : 0),
              right: _expandLeft ? (_isExpanded ? 8 : 0) : null,
              child: GestureDetector(
                onTap: _createMap,
                child: GlassPanel(
                  width: 28,
                  height: 28,
                  borderRadius: 8,
                  color: theme.cardColor.withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(6),
                  shadow: BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _open(),
        onExit: (_) => _scheduleClose(),
          child: GestureDetector(
            onTap: () {
              final name = NameGenerator.generate();
              widget.tabsController.addTab('maps/$name.db', name);
            },
            child: _overlayEntry == null
                ? Container(
                    width: _collapsedSize,
                    height: _collapsedSize,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  )
                : SizedBox(
                    width: _collapsedSize,
                    height: _collapsedSize,
                  ),
          ),
      ),
    );
  }
}

class _RecentMapTile extends StatelessWidget {
  final MapInfo map;
  final VoidCallback onTap;

  const _RecentMapTile({
    required this.map,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: HoverScaleButton(
        onTap: onTap,
        hoverScale: 1.02,
        pressScale: 0.98,
        borderRadius: BorderRadius.circular(6),
        builder: (context, isHovered, isPressed) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: isHovered
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 0.8,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 0.8,
                    ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isHovered
                        ? primaryColor.withValues(alpha: 0.18)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    size: 12,
                    color: isHovered
                        ? primaryColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    map.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                      color: isHovered
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isHovered)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 10,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
