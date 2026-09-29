import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/context_menu/context_menu_item.dart';
import 'package:centrode/shared/widgets/context_menu/context_menu_layout_delegate.dart';
import 'surfaces/double_edge_surface.dart';
import 'surfaces/gliding_lens.dart';

export 'package:centrode/shared/widgets/context_menu/context_menu_item.dart';
export 'package:centrode/shared/widgets/context_menu/context_menu_layout_delegate.dart'
    show MenuPositioningMode;

class CentrodeContextMenu {
  static OverlayEntry? show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
    Rect? targetRect,
    List<Rect> avoidRects = const [],
    Rect? avoidRect,
    MenuPositioningMode positioningMode = MenuPositioningMode.auto,
    VoidCallback? onDismissed,
    double? menuWidth,
    bool useGlidingLens = false,
    int? selectedIndex,
    bool showChevron = false,
  }) {
    final effectiveTargetRect =
        targetRect ?? Rect.fromLTWH(position.dx, position.dy, 0, 0);
    final effectiveAvoidRects = <Rect>[
      ...avoidRects,
      if (avoidRect != null) avoidRect,
    ];

    return showAt(
      context: context,
      targetRect: effectiveTargetRect,
      clickPosition: position,
      items: items,
      avoidRects: effectiveAvoidRects,
      positioningMode: positioningMode,
      onDismissed: onDismissed,
      menuWidth: menuWidth,
      useGlidingLens: useGlidingLens,
      selectedIndex: selectedIndex,
      showChevron: showChevron,
    );
  }

  static OverlayEntry? showAt({
    required BuildContext context,
    required Rect targetRect,
    Offset? clickPosition,
    required List<ContextMenuItem> items,
    List<Rect> avoidRects = const [],
    Rect? avoidRect,
    MenuPositioningMode positioningMode = MenuPositioningMode.auto,
    VoidCallback? onDismissed,
    double? menuWidth,
    bool useGlidingLens = false,
    int? selectedIndex,
    bool showChevron = false,
  }) {
    final visibleItems = items.where((item) => item.visible).toList();
    if (visibleItems.isEmpty) return null;

    final effectiveAvoidRects = <Rect>[
      ...avoidRects,
      if (avoidRect != null) avoidRect,
    ];

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    late OverlayEntry entry;
    bool isDismissed = false;

    void dismiss() {
      if (!isDismissed) {
        isDismissed = true;
        entry.remove();
        onDismissed?.call();
      }
    }

    entry = OverlayEntry(
      builder: (context) => Theme(
        data: theme,
        child: _ContextMenuRouteWidget(
          targetRect: targetRect,
          clickPosition: clickPosition,
          items: visibleItems,
          avoidRects: effectiveAvoidRects,
          positioningMode: positioningMode,
          onDismiss: dismiss,
          menuWidth: menuWidth,
          useGlidingLens: useGlidingLens,
          selectedIndex: selectedIndex,
          showChevron: showChevron,
        ),
      ),
    );

    overlay.insert(entry);
    return entry;
  }
}

class _ContextMenuRouteWidget extends StatefulWidget {
  final Rect targetRect;
  final Offset? clickPosition;
  final List<ContextMenuItem> items;
  final List<Rect> avoidRects;
  final MenuPositioningMode positioningMode;
  final VoidCallback onDismiss;
  final double? menuWidth;
  final bool useGlidingLens;
  final int? selectedIndex;
  final bool showChevron;

  const _ContextMenuRouteWidget({
    required this.targetRect,
    this.clickPosition,
    required this.items,
    this.avoidRects = const [],
    this.positioningMode = MenuPositioningMode.auto,
    required this.onDismiss,
    this.menuWidth,
    this.useGlidingLens = false,
    this.selectedIndex,
    this.showChevron = false,
  });

  @override
  State<_ContextMenuRouteWidget> createState() => _ContextMenuRouteWidgetState();
}

class _ContextMenuRouteWidgetState extends State<_ContextMenuRouteWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.selectedIndex ?? -1;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleKeyDown(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return;
    }

    final actionIndices = <int>[];
    for (int i = 0; i < widget.items.length; i++) {
      final it = widget.items[i];
      if (!it.isDivider && !it.isHeader && it.onTap != null) {
        actionIndices.add(i);
      }
    }

    if (actionIndices.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        final currentPos = actionIndices.indexOf(_focusedIndex);
        if (currentPos == -1 || currentPos == actionIndices.length - 1) {
          _focusedIndex = actionIndices.first;
        } else {
          _focusedIndex = actionIndices[currentPos + 1];
        }
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        final currentPos = actionIndices.indexOf(_focusedIndex);
        if (currentPos <= 0) {
          _focusedIndex = actionIndices.last;
        } else {
          _focusedIndex = actionIndices[currentPos - 1];
        }
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (_focusedIndex >= 0 && _focusedIndex < widget.items.length) {
        final item = widget.items[_focusedIndex];
        if (item.onTap != null) {
          widget.onDismiss();
          item.onTap!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyDown(event);
        return KeyEventResult.handled;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => widget.onDismiss(),
            ),
          ),
          CustomSingleChildLayout(
            delegate: ContextMenuLayoutDelegate(
              targetRect: widget.targetRect,
              clickPosition: widget.clickPosition,
              screenPadding: MediaQuery.of(context).padding,
              avoidRects: widget.avoidRects,
              positioningMode: widget.positioningMode,
              menuWidth: widget.menuWidth,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topLeft,
                child: _ContextMenuCard(
                  items: widget.items,
                  focusedIndex: _focusedIndex,
                  menuWidth: widget.menuWidth,
                  useGlidingLens: widget.useGlidingLens,
                  selectedIndex: widget.selectedIndex,
                  showChevron: widget.showChevron,
                  animationValue: _controller.value,
                  onSelect: (item) {
                    widget.onDismiss();
                    item.onTap?.call();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMenuCard extends StatefulWidget {
  final List<ContextMenuItem> items;
  final int focusedIndex;
  final ValueChanged<ContextMenuItem> onSelect;
  final double? menuWidth;
  final bool useGlidingLens;
  final int? selectedIndex;
  final bool showChevron;
  final double animationValue;

  const _ContextMenuCard({
    required this.items,
    required this.focusedIndex,
    required this.onSelect,
    this.menuWidth,
    required this.useGlidingLens,
    this.selectedIndex,
    required this.showChevron,
    required this.animationValue,
  });

  @override
  State<_ContextMenuCard> createState() => _ContextMenuCardState();
}

class _ContextMenuCardState extends State<_ContextMenuCard>
    with SingleTickerProviderStateMixin {
  int _hoveredIndex = -1;
  double _fromRowFraction = 0.0;
  double _toRowFraction = 0.0;
  bool _isLensTransitioning = false;
  late AnimationController _lensController;

  @override
  void initState() {
    super.initState();
    final initialPos = (widget.selectedIndex ?? 0).toDouble();
    _fromRowFraction = initialPos;
    _toRowFraction = initialPos;
    _hoveredIndex = widget.selectedIndex ?? -1;

    _lensController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _lensController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isLensTransitioning = false;
            _fromRowFraction = _toRowFraction;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ContextMenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedIndex != oldWidget.focusedIndex && widget.focusedIndex >= 0) {
      _onHoverRow(widget.focusedIndex);
    }
  }

  @override
  void dispose() {
    _lensController.dispose();
    super.dispose();
  }

  void _onHoverRow(int targetIndex) {
    if (_hoveredIndex == targetIndex && !_isLensTransitioning) return;
    final startPos = _isLensTransitioning
        ? (_fromRowFraction +
            (_toRowFraction - _fromRowFraction) *
                CentrodeGlidingLensPhysics.calculatePosProgress(_lensController.value))
        : _fromRowFraction;

    setState(() {
      _hoveredIndex = targetIndex;
      _fromRowFraction = startPos;
      _toRowFraction = targetIndex.toDouble();
      _isLensTransitioning = true;
    });
    _lensController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    const double rowHeight = UiControlSize.standard;
    const double paddingV = 5.0;
    const double paddingH = 4.0;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: widget.menuWidth,
        child: CentrodeDoubleEdgeSurface(
          cornerRadius: UiRadius.card,
          accentColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.useGlidingLens)
                AnimatedBuilder(
                  animation: _lensController,
                  builder: (context, _) {
                    final t = _lensController.value;
                    final posProgress = _isLensTransitioning
                        ? CentrodeGlidingLensPhysics.calculatePosProgress(t)
                        : 1.0;
                    final stretch = _isLensTransitioning
                        ? CentrodeGlidingLensPhysics.calculateStretch(t)
                        : 0.0;
                    final activeFraction = _isLensTransitioning
                        ? _fromRowFraction + (_toRowFraction - _fromRowFraction) * posProgress
                        : (_hoveredIndex >= 0
                            ? _hoveredIndex.toDouble()
                            : (widget.selectedIndex ?? 0).toDouble());

                    final rowDistance = (_toRowFraction - _fromRowFraction).abs();
                    final maxStretch = (rowHeight * 0.40 * rowDistance.clamp(1.0, 2.5)).clamp(8.0, 36.0);
                    final currentStretch = stretch * maxStretch;
                    final currentHeight = rowHeight + currentStretch;

                    final baseCenterY = (activeFraction + 0.5) * rowHeight;
                    final dir = (_toRowFraction >= _fromRowFraction) ? 1.0 : -1.0;
                    final leadBias = (1.0 - (2.0 * posProgress).clamp(0.0, 1.0)) * 0.44 * dir * currentStretch;
                    final centerY = baseCenterY + leadBias;
                    final top = centerY - (currentHeight / 2);

                    return CentrodeGlidingLens(
                      direction: Axis.vertical,
                      activeRect: Rect.fromLTWH(0, top, (widget.menuWidth ?? 180) - (paddingH * 2), currentHeight),
                      cornerRadius: UiRadius.control,
                      accentColor: accentColor,
                      isVisible: _hoveredIndex >= 0 || widget.selectedIndex != null,
                    );
                  },
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < widget.items.length; i++)
                    _buildEntry(context, widget.items[i], i, rowHeight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, ContextMenuItem item, int index, double rowHeight) {
    if (item.isDivider) {
      return Container(
        height: UiStrokeWidth.subtle,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        color: Theme.of(context).dividerColor,
      );
    }

    if (item.isHeader) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(left: 10.0, top: 6.0, bottom: 2.0),
        child: Text(
          item.label.toUpperCase(),
          style: TextStyle(
            fontSize: UiFont.micro,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    final isFocused = index == widget.focusedIndex;
    final isHovered = index == _hoveredIndex;
    final isSelected = index == widget.selectedIndex;

    if (item.builder != null) {
      return MouseRegion(
        onEnter: (_) {
          _onHoverRow(index);
        },
        onExit: (_) {
          if (!widget.useGlidingLens) {
            setState(() => _hoveredIndex = -1);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.onTap,
          child: item.builder!(context, isFocused || isHovered),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHoverRow(index),
      onExit: (_) {
        if (!widget.useGlidingLens) {
          setState(() => _hoveredIndex = -1);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(item),
        child: SizedBox(
          height: rowHeight,
          child: _ContextMenuItemRow(
            item: item,
            isFocused: isFocused,
            isHovered: isHovered,
            isSelected: isSelected,
            useGlidingLens: widget.useGlidingLens,
            showChevron: widget.showChevron && isSelected,
            animationValue: widget.animationValue,
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItemRow extends StatelessWidget {
  final ContextMenuItem item;
  final bool isFocused;
  final bool isHovered;
  final bool isSelected;
  final bool useGlidingLens;
  final bool showChevron;
  final double animationValue;

  const _ContextMenuItemRow({
    required this.item,
    required this.isFocused,
    required this.isHovered,
    required this.isSelected,
    required this.useGlidingLens,
    required this.showChevron,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = item.isDestructive;
    final isActive = isHovered || isFocused;

    final baseTextColor = isDestructive
        ? const Color(0xFFFF5C5C)
        : (theme.textTheme.bodyMedium?.color ?? Colors.white);

    final hoverBg = isDestructive
        ? const Color(0xFFFF5C5C).withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: (!useGlidingLens && isActive) ? hoverBg : Colors.transparent,
        borderRadius: BorderRadius.circular(UiRadius.control),
      ),
      child: Row(
        children: [
          if (item.leadingIcon != null) ...[
            Icon(
              item.leadingIcon,
              size: UiIconSize.dense,
              color: isDestructive
                  ? const Color(0xFFFF5C5C)
                  : (isActive ? theme.colorScheme.primary : baseTextColor.withValues(alpha: 0.75)),
            ),
            const SizedBox(width: UiSpacing.standard),
          ],
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: UiFont.standard,
                fontWeight: isSelected ? FontWeight.w700 : (isActive ? FontWeight.w600 : FontWeight.w500),
                color: isActive ? Colors.white : baseTextColor,
              ),
            ),
          ),
          if (showChevron) ...[
            AnimatedRotation(
              turns: animationValue * 0.5,
              duration: Duration.zero,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: UiIconSize.standard,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: UiSpacing.tight),
          ],
          if (item.shortcut != null) ...[
            const SizedBox(width: UiSpacing.standard),
            Text(
              item.shortcut!,
              style: TextStyle(
                fontSize: UiFont.micro,
                fontFamily: 'monospace',
                color: isDestructive
                    ? const Color(0xFFFF5C5C).withValues(alpha: 0.6)
                    : (theme.textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
