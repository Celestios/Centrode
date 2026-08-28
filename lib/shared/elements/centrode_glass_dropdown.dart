import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class CentrodeDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final TextStyle? previewStyle;

  const CentrodeDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.previewStyle,
  });
}

/// Frosted glass dropdown selector for Centrode forms and inspector panels.
class CentrodeGlassDropdown<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<CentrodeDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;
  final double labelWidth;

  const CentrodeGlassDropdown({
    super.key,
    this.label = '',
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.activeColor,
    this.height = UiControlSize.standard,
    this.labelWidth = 75.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeValue = items.any((item) => item.value == selectedValue)
        ? selectedValue
        : (items.isNotEmpty ? items.first.value : null);

    final dropdownBox = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: UiSpacing.standard),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(UiRadius.control),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: UiIconSize.dense,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          dropdownColor: const Color(0xFF151820),
          borderRadius: BorderRadius.circular(UiRadius.card),
          style: TextStyle(
            fontSize: UiFont.micro,
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
                      fontSize: UiFont.compact,
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
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontSize: UiFont.micro,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: dropdownBox),
        ],
      ),
    );
  }
}
