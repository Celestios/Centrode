import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class SegmentData<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
  final TextStyle? style;

  const SegmentData({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
    this.style,
  });
}

/// Glass Segmented Mode Switcher with sliding indicator and full click + drag support.
class SegmentedGlassSwitcher<T> extends StatefulWidget {
  final List<SegmentData<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;

  const SegmentedGlassSwitcher({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
    this.height = 26.0,
  });

  @override
  State<SegmentedGlassSwitcher<T>> createState() => _SegmentedGlassSwitcherState<T>();
}

class _SegmentedGlassSwitcherState<T> extends State<SegmentedGlassSwitcher<T>> {
  bool _isDragging = false;

  void _handlePointer(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.segments.isEmpty) return;
    final itemWidth = totalWidth / widget.segments.length;
    final targetIndex = (localPosition.dx / itemWidth).floor().clamp(0, widget.segments.length - 1);
    final targetValue = widget.segments[targetIndex].value;
    if (targetValue != widget.selectedValue) {
      widget.onSelected(targetValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIndex = widget.segments.indexWhere((s) => s.value == widget.selectedValue);
    final safeIndex = activeIndex >= 0 ? activeIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final count = widget.segments.isEmpty ? 1 : widget.segments.length;
        final innerWidth = (totalWidth - 4.0).clamp(0.0, double.infinity);
        final itemWidth = count > 0 && innerWidth > 0 ? innerWidth / count : 0.0;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            setState(() => _isDragging = true);
            _handlePointer(event.localPosition - const Offset(2, 2), innerWidth);
          },
          onPointerMove: (event) {
            _handlePointer(event.localPosition - const Offset(2, 2), innerWidth);
          },
          onPointerUp: (_) {
            setState(() => _isDragging = false);
          },
          onPointerCancel: (_) {
            setState(() => _isDragging = false);
          },
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(UiRadius.card),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: UiStrokeWidth.subtle,
              ),
            ),
            child: Stack(
              children: [
                // Sliding indicator pill
                AnimatedPositioned(
                  duration: Duration(milliseconds: _isDragging ? 50 : 180),
                  curve: Curves.easeOutCubic,
                  left: safeIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.activeColor.withValues(alpha: _isDragging ? 0.35 : 0.28),
                      borderRadius: BorderRadius.circular(UiRadius.control),
                      border: Border.all(
                        color: widget.activeColor.withValues(alpha: _isDragging ? 0.75 : 0.5),
                        width: UiStrokeWidth.subtle,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: _isDragging ? 0.35 : 0.2),
                          blurRadius: _isDragging ? 8 : 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive segment labels/icons
                Row(
                  children: [
                    for (int i = 0; i < widget.segments.length; i++) ...[
                      Expanded(
                        child: Tooltip(
                          message: widget.segments[i].tooltip ?? widget.segments[i].label,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.segments[i].icon != null) ...[
                                      Icon(
                                        widget.segments[i].icon,
                                        size: 12,
                                        color: i == safeIndex
                                            ? widget.activeColor
                                            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
                                                Colors.white54,
                                      ),
                                      if (widget.segments[i].label.isNotEmpty)
                                        const SizedBox(width: 3),
                                    ],
                                    if (widget.segments[i].label.isNotEmpty)
                                      Text(
                                        widget.segments[i].label,
                                        maxLines: 1,
                                        style: (widget.segments[i].style ?? const TextStyle()).copyWith(
                                          fontSize: widget.segments[i].style?.fontSize ?? 10.0,
                                          fontWeight: i == safeIndex
                                              ? FontWeight.w700
                                              : (widget.segments[i].style?.fontWeight ?? FontWeight.w500),
                                          color: i == safeIndex
                                              ? widget.activeColor
                                              : (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                                                  Colors.white70),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
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
      },
    );
  }
}
