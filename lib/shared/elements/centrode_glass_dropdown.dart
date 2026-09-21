import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';

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
    final palette = CentrodeDerivedPalette.of(context);

    final dropdownBox = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: UiSpacing.standard),
      decoration: BoxDecoration(
        color: palette.surface.controlBackground,
        borderRadius: BorderRadius.circular(UiRadius.control),
        border: Border.all(
          color: palette.surface.controlBorder,
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selectedValue,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: UiIconSize.dense,
            color: palette.surface.controlForeground.withValues(alpha: 0.6),
          ),
          dropdownColor: palette.surface.cardBackground,
          borderRadius: BorderRadius.circular(UiRadius.card),
          style: TextStyle(
            fontSize: UiFont.micro,
            fontWeight: FontWeight.w600,
            color: palette.surface.controlForeground,
          ),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
          items: items.map((item) {
            final itemColor = item.value == selectedValue
                ? activeColor
                : palette.textOn(palette.surface.cardBackground).withValues(alpha: 0.85);
            return DropdownMenuItem<T>(
              value: item.value,
              child: Text(
                item.label,
                style: item.previewStyle ??
                    TextStyle(
                      fontSize: UiFont.compact,
                      color: itemColor,
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
                color: palette.surface.controlForeground
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: dropdownBox),
        ],
      ),
    );
  }
}
