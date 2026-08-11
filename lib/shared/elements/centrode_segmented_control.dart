import 'package:flutter/material.dart';

typedef SegmentItem<T> = ({
  IconData icon,
  String label,
  T mode,
  String? tooltip,
  String? accentBadge,
});

class CentrodeSegmentedControl<T> extends StatefulWidget {
  final List<SegmentItem<T>> items;
  final T currentMode;
  final ValueChanged<T> onSelected;
  final bool isCompact;

  static const defaultCompactItemWidth = 34.0;
  static const defaultExpandedItemWidth = 88.0;

  const CentrodeSegmentedControl({
    super.key,
    required this.items,
    required this.currentMode,
    required this.onSelected,
    required this.isCompact,
  });

  @override
  State<CentrodeSegmentedControl<T>> createState() => _CentrodeSegmentedControlState<T>();
}

class _CentrodeSegmentedControlState<T> extends State<CentrodeSegmentedControl<T>> {
  bool _isPressed = false;

  void _handlePointerPosition(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.items.isEmpty) return;
    final itemWidth = totalWidth / widget.items.length;
    final targetIndex = (localPosition.dx / itemWidth).floor().clamp(0, widget.items.length - 1);
    final targetMode = widget.items[targetIndex].mode;
    if (targetMode != widget.currentMode) {
      widget.onSelected(targetMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final activeIndex = widget.items.indexWhere((item) => item.mode == widget.currentMode);
    final safeIndex = activeIndex >= 0 ? activeIndex : 0;
    final itemWidth = widget.isCompact ? 34.0 : 88.0;

    return Listener(
      onPointerDown: (event) {
        setState(() => _isPressed = true);
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        _handlePointerPosition(local, box.size.width);
      },
      onPointerMove: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        _handlePointerPosition(local, box.size.width);
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: safeIndex * itemWidth,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: AnimatedScale(
                scale: _isPressed ? 1.14 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: _isPressed ? 0.58 : 0.45),
                        primaryColor.withValues(alpha: _isPressed ? 0.35 : 0.22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: _isPressed ? 0.9 : 0.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: _isPressed ? 0.5 : 0.35),
                        blurRadius: _isPressed ? 18 : 12,
                        spreadRadius: _isPressed ? 1 : -0.5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.items.length; i++) ...[
                  SizedBox(
                    width: itemWidth,
                    height: 28,
                    child: Tooltip(
                      message: widget.items[i].tooltip ?? widget.items[i].label,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.items[i].icon,
                            size: 16,
                            color: i == safeIndex
                                ? textColor
                                : textColor.withValues(alpha: 0.75),
                          ),
                          if (!widget.isCompact) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.items[i].label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: i == safeIndex ? FontWeight.bold : FontWeight.w500,
                                  color: i == safeIndex
                                      ? textColor
                                      : textColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                          if (!widget.isCompact && widget.items[i].accentBadge != null) ...[
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                widget.items[i].accentBadge!,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
