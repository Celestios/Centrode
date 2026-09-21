import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
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
  State<CentrodeSegmentedControl<T>> createState() =>
      _CentrodeSegmentedControlState<T>();
}

class _CentrodeSegmentedControlState<T>
    extends State<CentrodeSegmentedControl<T>> {
  bool _isPressed = false;

  void _handlePointerPosition(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.items.isEmpty) return;
    final itemWidth = totalWidth / widget.items.length;
    final targetIndex = (localPosition.dx / itemWidth).floor().clamp(
      0,
      widget.items.length - 1,
    );
    final targetMode = widget.items[targetIndex].mode;
    if (targetMode != widget.currentMode) {
      widget.onSelected(targetMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = CentrodeDerivedPalette.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = palette.surface.controlForeground;
    final activeTextColor = palette.textOn(primaryColor);

    final activeIndex = widget.items.indexWhere(
      (item) => item.mode == widget.currentMode,
    );
    assert(
      activeIndex >= 0,
      'currentMode ${widget.currentMode} not found in items',
    );

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
          color: palette.surface.controlBackground,
          borderRadius: BorderRadius.circular(UiRadius.panel),
          border: Border.all(
            color: palette.surface.controlBorder,
            width: UiStrokeWidth.subtle,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double dynamicItemWidth;
            if (constraints.hasBoundedWidth) {
              dynamicItemWidth = constraints.maxWidth / widget.items.length;
            } else {
              dynamicItemWidth = widget.isCompact
                  ? CentrodeSegmentedControl.defaultCompactItemWidth
                  : CentrodeSegmentedControl.defaultExpandedItemWidth;
            }
            final totalWidth = dynamicItemWidth * widget.items.length;
            final stack = Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: UiMotion.standard,
                  curve: Curves.easeOutCubic,
                  left: activeIndex * dynamicItemWidth,
                  top: 0,
                  bottom: 0,
                  width: dynamicItemWidth,
                  child: AnimatedScale(
                    scale: _isPressed ? 1.14 : 1.0,
                    duration: UiMotion.fast,
                    curve: Curves.easeOutBack,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(UiRadius.card),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(
                              alpha: _isPressed ? 0.58 : 0.45,
                            ),
                            primaryColor.withValues(
                              alpha: _isPressed ? 0.35 : 0.22,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: primaryColor.withValues(
                            alpha: _isPressed ? 0.9 : 0.65,
                          ),
                          width: UiStrokeWidth.thick,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(
                              alpha: _isPressed ? 0.5 : 0.35,
                            ),
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
                  children: [
                    for (int i = 0; i < widget.items.length; i++) ...[
                      Expanded(
                        child: SizedBox(
                          height: UiControlSize.dense,
                          child: Tooltip(
                            message:
                                widget.items[i].tooltip ??
                                widget.items[i].label,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.items[i].icon,
                                  size: UiIconSize.dense,
                                  color: i == activeIndex
                                      ? activeTextColor
                                      : textColor.withValues(alpha: 0.75),
                                ),
                                if (!widget.isCompact) ...[
                                  const SizedBox(width: UiSpacing.tight),
                                  Flexible(
                                    child: Text(
                                      widget.items[i].label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: UiFont.compact,
                                        fontWeight: i == activeIndex
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: i == activeIndex
                                            ? activeTextColor
                                            : textColor.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                ],
                                if (!widget.isCompact &&
                                    widget.items[i].accentBadge != null) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      widget.items[i].accentBadge!,
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        color: palette.textOn(primaryColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
            return SizedBox(
              width: constraints.hasBoundedWidth ? null : totalWidth,
              child: stack,
            );
          },
        ),
      ),
    );
  }
}
