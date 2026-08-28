import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Pattern A: Tactile Grid of Visual Preview Tiles for shapes, routing vectors, and caps.
class VisualShapeSelector<T> extends StatelessWidget {
  final List<ShapeTileData<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const VisualShapeSelector({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final isSelected = item.value == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(item.value),
          child: AnimatedContainer(
            duration: UiMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(UiRadius.card),
              border: Border.all(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.2 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        spreadRadius: -1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 13,
                  color: isSelected
                      ? activeColor
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: UiSpacing.tight),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: UiFont.compact,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ShapeTileData<T> {
  final T value;
  final String label;
  final IconData icon;

  const ShapeTileData({
    required this.value,
    required this.label,
    required this.icon,
  });
}
