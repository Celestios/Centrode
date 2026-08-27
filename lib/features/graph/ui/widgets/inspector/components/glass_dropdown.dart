import 'package:flutter/material.dart';

class GlassDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final TextStyle? previewStyle;

  const GlassDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.previewStyle,
  });
}

/// Frosted glass dropdown selector matching Centrode inspector styling.
class GlassDropdown<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<GlassDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;

  const GlassDropdown({
    super.key,
    this.label = '',
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.activeColor,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeValue = items.any((item) => item.value == selectedValue)
        ? selectedValue
        : (items.isNotEmpty ? items.first.value : null);

    final dropdownBox = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          dropdownColor: const Color(0xFF151820),
          borderRadius: BorderRadius.circular(8),
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color ?? Colors.white,
          ),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Text(
                item.label,
                style: item.previewStyle ??
                    TextStyle(
                      fontSize: 10.5,
                      color: item.value == selectedValue
                          ? activeColor
                          : Colors.white.withValues(alpha: 0.85),
                    ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: dropdownBox,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: dropdownBox),
        ],
      ),
    );
  }
}
