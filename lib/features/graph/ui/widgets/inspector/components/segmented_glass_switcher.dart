import 'package:flutter/material.dart';

/// Pattern B: Glass Segmented Mode Switcher with sliding indicator feel.
class SegmentedGlassSwitcher<T> extends StatelessWidget {
  final List<SegmentData<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const SegmentedGlassSwitcher({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Row(
        children: segments.map((seg) {
          final isSelected = seg.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(seg.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.28)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seg.icon != null) ...[
                      Icon(
                        seg.icon,
                        size: 12,
                        color: isSelected
                            ? activeColor
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      seg.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? activeColor
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SegmentData<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentData({
    required this.value,
    required this.label,
    this.icon,
  });
}
