import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

class ContextMenuItem {
  final String label;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final String? shortcut;
  final bool isDestructive;
  final bool isDivider;
  final bool isHeader;
  final bool visible;

  const ContextMenuItem({
    this.label = '',
    this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.isDestructive = false,
    this.isDivider = false,
    this.isHeader = false,
    this.visible = true,
  });

  const ContextMenuItem.action({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.visible = true,
  })  : isDestructive = false,
        isDivider = false,
        isHeader = false;

  const ContextMenuItem.destructive({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.visible = true,
  })  : isDestructive = true,
        isDivider = false,
        isHeader = false;

  const ContextMenuItem.divider({this.visible = true})
      : label = '',
        onTap = null,
        leadingIcon = null,
        shortcut = null,
        isDestructive = false,
        isDivider = true,
        isHeader = false;

  const ContextMenuItem.header(this.label, {this.visible = true})
      : onTap = null,
        leadingIcon = null,
        shortcut = null,
        isDestructive = false,
        isDivider = false,
        isHeader = true;
}

typedef CentrodeMenuItem = ContextMenuItem;

class ContextMenuOverlay {
  static OverlayEntry? show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
    Rect? targetRect,
    List<Rect> avoidRects = const [],
    Rect? avoidRect,
    VoidCallback? onDismissed,
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
      onDismissed: onDismissed,
    );
  }

  static OverlayEntry? showAt({
    required BuildContext context,
    required Rect targetRect,
    Offset? clickPosition,
    required List<ContextMenuItem> items,
    List<Rect> avoidRects = const [],
    Rect? avoidRect,
    VoidCallback? onDismissed,
  }) {
    final visibleItems = items.where((item) => item.visible).toList();
    if (visibleItems.isEmpty) return null;

    final effectiveAvoidRects = <Rect>[
      ...avoidRects,
      if (avoidRect != null) avoidRect,
    ];

    final overlay = Overlay.of(context);
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
      builder: (context) => _ContextMenuRouteWidget(
        targetRect: targetRect,
        clickPosition: clickPosition,
        items: visibleItems,
        avoidRects: effectiveAvoidRects,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(entry);
    return entry;
  }
}

typedef CentrodeContextMenu = ContextMenuOverlay;

class _ContextMenuRouteWidget extends StatefulWidget {
  final Rect targetRect;
  final Offset? clickPosition;
  final List<ContextMenuItem> items;
  final List<Rect> avoidRects;
  final VoidCallback onDismiss;

  const _ContextMenuRouteWidget({
    required this.targetRect,
    this.clickPosition,
    required this.items,
    this.avoidRects = const [],
    required this.onDismiss,
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
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
          // Dismissal backdrop
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => widget.onDismiss(),
            ),
          ),
          // Positioned Context Menu
          CustomSingleChildLayout(
            delegate: _ContextMenuLayoutDelegate(
              targetRect: widget.targetRect,
              clickPosition: widget.clickPosition,
              screenPadding: MediaQuery.of(context).padding,
              avoidRects: widget.avoidRects,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topLeft,
                child: _ContextMenuCard(
                  items: widget.items,
                  focusedIndex: _focusedIndex,
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

class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect targetRect;
  final Offset? clickPosition;
  final EdgeInsets screenPadding;
  final List<Rect> avoidRects;

  const _ContextMenuLayoutDelegate({
    required this.targetRect,
    this.clickPosition,
    required this.screenPadding,
    this.avoidRects = const [],
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return const BoxConstraints(
      minWidth: 180.0,
      maxWidth: 260.0,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const margin = 8.0;
    const gap = 6.0;

    final bool isAreaTarget = targetRect.width > 2.0 && targetRect.height > 2.0;

    double x;
    double y;

    if (!isAreaTarget) {
      final click = clickPosition ?? targetRect.topLeft;
      x = click.dx;
      y = click.dy;

      if (x + childSize.width > size.width - margin) {
        x = x - childSize.width;
      }
      if (y + childSize.height > size.height - margin) {
        y = y - childSize.height;
      }
    } else {
      final click = clickPosition ?? targetRect.center;
      final bool preferRight = click.dx >= targetRect.center.dx;

      final rightX = targetRect.right + gap;
      final canFitRight = rightX + childSize.width <= size.width - margin;

      final leftX = targetRect.left - childSize.width - gap;
      final canFitLeft = leftX >= margin;

      final bottomY = targetRect.bottom + gap;
      final canFitBottom = bottomY + childSize.height <= size.height - margin;

      final topY = targetRect.top - childSize.height - gap;
      final canFitTop = topY >= margin;

      if (preferRight && canFitRight) {
        x = rightX;
      } else if (!preferRight && canFitLeft) {
        x = leftX;
      } else if (canFitRight) {
        x = rightX;
      } else if (canFitLeft) {
        x = leftX;
      } else {
        x = targetRect.left.clamp(margin, size.width - childSize.width - margin);
      }

      if (x == rightX || x == leftX) {
        y = click.dy.clamp(margin, size.height - childSize.height - margin);
      } else {
        if (canFitBottom) {
          y = bottomY;
        } else if (canFitTop) {
          y = topY;
        } else {
          y = (size.height - childSize.height) / 2;
        }
      }
    }

    Rect candidate = Rect.fromLTWH(x, y, childSize.width, childSize.height);

    for (final obstacle in avoidRects) {
      if (candidate.overlaps(obstacle)) {
        final rightX = obstacle.right + gap;
        final leftX = obstacle.left - childSize.width - gap;
        final bottomY = obstacle.bottom + gap;
        final topY = obstacle.top - childSize.height - gap;

        final canFitRight = rightX + childSize.width <= size.width - margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(rightX, y, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitLeft = leftX >= margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(leftX, y, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitBottom = bottomY + childSize.height <= size.height - margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(x, bottomY, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitTop = topY >= margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(x, topY, childSize.width, childSize.height)
                    .overlaps(targetRect));

        if (canFitLeft) {
          x = leftX;
        } else if (canFitRight) {
          x = rightX;
        } else if (canFitBottom) {
          y = bottomY;
        } else if (canFitTop) {
          y = topY;
        }
        candidate = Rect.fromLTWH(x, y, childSize.width, childSize.height);
      }
    }

    if (x < margin) x = margin;
    if (y < margin) y = margin;
    if (x + childSize.width > size.width - margin) {
      x = size.width - childSize.width - margin;
    }
    if (y + childSize.height > size.height - margin) {
      y = size.height - childSize.height - margin;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _ContextMenuLayoutDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        clickPosition != oldDelegate.clickPosition ||
        avoidRects != oldDelegate.avoidRects ||
        screenPadding != oldDelegate.screenPadding;
  }
}

class _ContextMenuCard extends StatelessWidget {
  final List<ContextMenuItem> items;
  final int focusedIndex;
  final ValueChanged<ContextMenuItem> onSelect;

  const _ContextMenuCard({
    required this.items,
    required this.focusedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1B1D24) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(UiRadius.card),
          border: Border.all(
            color: borderColor,
            width: UiStrokeWidth.subtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
              blurRadius: 12.0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 24.0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++)
                _buildEntry(context, items[i], isFocused: i == focusedIndex, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, ContextMenuItem item,
      {required bool isFocused, required bool isDark}) {
    if (item.isDivider) {
      return Container(
        height: UiStrokeWidth.subtle,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
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

    return _ContextMenuItemRow(
      item: item,
      isFocused: isFocused,
      onTap: () => onSelect(item),
    );
  }
}

class _ContextMenuItemRow extends StatefulWidget {
  final ContextMenuItem item;
  final bool isFocused;
  final VoidCallback onTap;

  const _ContextMenuItemRow({
    required this.item,
    required this.isFocused,
    required this.onTap,
  });

  @override
  State<_ContextMenuItemRow> createState() => _ContextMenuItemRowState();
}

class _ContextMenuItemRowState extends State<_ContextMenuItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = widget.item.isDestructive;
    final isActive = _isHovered || widget.isFocused;

    final baseTextColor = isDestructive
        ? const Color(0xFFFF5C5C)
        : (theme.textTheme.bodyMedium?.color ?? Colors.white);

    final hoverBg = isDestructive
        ? const Color(0xFFFF5C5C).withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: UiControlSize.standard,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: isActive ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(UiRadius.control),
          ),
          child: Row(
            children: [
              if (widget.item.leadingIcon != null) ...[
                Icon(
                  widget.item.leadingIcon,
                  size: UiIconSize.dense,
                  color: isDestructive
                      ? const Color(0xFFFF5C5C)
                      : baseTextColor.withValues(alpha: 0.75),
                ),
                const SizedBox(width: UiSpacing.standard),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: UiFont.standard,
                    fontWeight: FontWeight.w500,
                    color: baseTextColor,
                  ),
                ),
              ),
              if (widget.item.shortcut != null) ...[
                const SizedBox(width: UiSpacing.standard),
                Text(
                  widget.item.shortcut!,
                  style: TextStyle(
                    fontSize: UiFont.micro,
                    fontFamily: 'monospace',
                    color: isDestructive
                        ? const Color(0xFFFF5C5C).withValues(alpha: 0.6)
                        : (theme.textTheme.bodySmall?.color ?? Colors.grey)
                            .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
