import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import '../utils/color_theory_engine.dart';

class CentrodeColorOption<T> {
  final T value;
  final Color? color;
  final String label;
  final bool isNone;

  const CentrodeColorOption({
    required this.value,
    this.color,
    required this.label,
    this.isNone = false,
  });
}

/// Standardized circular color indicator dot.
class CentrodeColorDot extends StatelessWidget {
  final Color? color;
  final bool isNone;
  final double size;
  final bool isSelected;
  final Color? selectedBorderColor;

  const CentrodeColorDot({
    super.key,
    this.color,
    this.isNone = false,
    this.size = 12.0,
    this.isSelected = false,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final fallbackSelectedBorder = palette.borderStrong;
    final unselectedBorder = palette.borderSubtle;

    if (isNone || color == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (selectedBorderColor ?? fallbackSelectedBorder)
                : unselectedBorder,
            width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.standard,
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.7,
            height: 1.0,
            color: palette.semantic.danger,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? (selectedBorderColor ?? fallbackSelectedBorder)
              : unselectedBorder,
          width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.subtle,
        ),
      ),
    );
  }
}

/// Pill-style button that opens a popup color picker menu.
class CentrodeColorPillButton<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<CentrodeColorOption<T>> options;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;

  const CentrodeColorPillButton({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.activeColor,
    this.height = UiControlSize.dense,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final matchingOpt = options.cast<CentrodeColorOption<T>?>().firstWhere(
      (opt) => opt?.value == selectedValue,
      orElse: () => null,
    );
    final currentOpt = matchingOpt ??
        CentrodeColorOption<T>(
          value: selectedValue,
          color: selectedValue is Color ? selectedValue as Color : null,
          label: selectedValue is Color
              ? ColorTheoryEngine.toHex(selectedValue as Color)
              : (selectedValue?.toString() ?? 'None'),
          isNone: selectedValue == null || selectedValue == 'none',
        );

    return PopupMenuButton<T>(
      tooltip: '$label: ${currentOpt.label}',
      color: palette.surface.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.card),
        side: BorderSide(
          color: palette.surface.controlBorder,
          width: UiStrokeWidth.subtle,
        ),
      ),
      offset: const Offset(0, 34),
      onSelected: onSelected,
      itemBuilder: (context) {
        final cardBg = palette.surface.cardBackground;
        final cardText = palette.textOn(cardBg);
        return options.map((opt) {
          final isSel = opt.value == selectedValue;
          return PopupMenuItem<T>(
            value: opt.value,
            height: height,
            child: Row(
              children: [
                CentrodeColorDot(
                  color: opt.color,
                  isNone: opt.isNone,
                  size: UiIconSize.dense,
                  isSelected: isSel,
                  selectedBorderColor: activeColor,
                ),
                const SizedBox(width: UiSpacing.standard),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: UiFont.compact,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel
                        ? activeColor
                        : cardText.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: UiSpacing.tight),
        decoration: BoxDecoration(
          color: palette.surface.controlBackground,
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(
            color: palette.surface.controlBorder,
            width: UiStrokeWidth.subtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CentrodeColorDot(
              color: currentOpt.color,
              isNone: currentOpt.isNone,
              size: UiIconSize.dense,
            ),
            const SizedBox(width: UiSpacing.tight),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: UiFont.standard,
                  fontWeight: FontWeight.w500,
                  color: palette.surface.controlForeground.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
