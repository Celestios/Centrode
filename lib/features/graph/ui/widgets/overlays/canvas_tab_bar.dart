import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/utils/name_generator.dart';
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
  static const double _expandedWidth = 140.0;
  static const double _headerHeight = 36.0;
  static const double _itemHeight = 32.0;

  static const _duration = Duration(milliseconds: 250);
  static const _closeDelay = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _closeTimer;

  bool _isExpanded = false;

  List<_MenuItem> get _items => [
        _MenuItem(Icons.insert_drive_file_outlined, 'Graph', () {
          final name = NameGenerator.generate();
          widget.tabsController.addTab('maps/$name.db', name);
        }),
        _MenuItem(Icons.note_add_outlined, 'Blank', () {
          final name = NameGenerator.generate();
          widget.tabsController.addTab('maps/$name.db', name);
        }),
      ];

  double get _expandedHeight =>
      _headerHeight + (_items.length * _itemHeight);

  void _open() {
    _closeTimer?.cancel();
    _closeTimer = null;

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

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;

    setState(() {
      _isExpanded = value;
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _cancelClose();

    if (_overlayEntry != null) return;

    final size = Size(_expandedWidth, _expandedHeight);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Material(
              type: MaterialType.transparency,
              child: Align(
                alignment: Alignment.topLeft,
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
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    _isExpanded = false;
    _overlayEntry!.markNeedsBuild();

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
    super.dispose();
  }

  Widget _buildAnimatedBox({
    required ThemeData theme,
    required Color primaryColor,
  }) {
    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: _isExpanded ? _expandedWidth : _collapsedSize,
      height: _isExpanded ? _expandedHeight : _collapsedSize,
      decoration: BoxDecoration(
        color: _isExpanded
            ? theme.cardColor.withValues(alpha: 0.72)
            : theme.cardColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(
          _isExpanded ? 12 : 10,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: _headerHeight - 2,
            left: 4,
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: _duration,
              curve: _curve,
              child: IgnorePointer(
                ignoring: !_isExpanded,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in _items)
                      _MenuItemWidget(
                        item: item,
                        onTap: () {
                          item.onTap();
                          _close();
                        },
                        primaryColor: primaryColor,
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: _isExpanded
                ? Alignment.topRight
                : Alignment.topLeft,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.add_rounded,
                size: 14,
              ),
            ),
          ),
        ],
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
          child: AnimatedOpacity(
            opacity: _overlayEntry != null ? 0 : 1,
            duration: _duration,
            curve: _curve,
            child: Container(
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
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}

class _MenuItemWidget extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  final Color primaryColor;
  final ThemeData theme;

  const _MenuItemWidget({
    required this.item,
    required this.onTap,
    required this.primaryColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 13, color: primaryColor.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
