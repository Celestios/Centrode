import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';

class CentrodeSquareOption<T> {
  final T value;
  final IconData? icon;
  final String? label;
  final TextStyle? labelStyle;
  final String tooltip;

  const CentrodeSquareOption({
    required this.value,
    this.icon,
    this.label,
    this.labelStyle,
    required this.tooltip,
  });
}

/// Standalone square toggle button for binary options or toolbar actions.
class CentrodeSquareToggle extends StatelessWidget {
  final bool isActive;
  final IconData? icon;
  final String? label;
  final TextStyle? labelStyle;
  final String tooltip;
  final VoidCallback onTap;
  final Color activeColor;
  final double height;
  final double? width;
  final double iconSize;

  const CentrodeSquareToggle({
    super.key,
    required this.isActive,
    this.icon,
    this.label,
    this.labelStyle,
    required this.tooltip,
    required this.onTap,
    required this.activeColor,
    this.height = UiControlSize.dense,
    this.width,
    this.iconSize = UiIconSize.dense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = CentrodeDerivedPalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseControlBg = palette.surface.controlBackground;
    final controlFg = palette.surface.controlForeground;

    final backgroundColor = isActive
        ? activeColor.withValues(alpha: isDark ? 0.28 : 0.18)
        : baseControlBg;

    final foregroundColor = isActive
        ? activeColor
        : controlFg.withValues(alpha: 0.75);

    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.6)
        : palette.surface.controlBorder;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: UiMotion.fast,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(UiRadius.control),
            border: Border.all(
              color: borderColor,
              width: UiStrokeWidth.subtle,
            ),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: (labelStyle ?? const TextStyle()).copyWith(
                      color: foregroundColor,
                      fontSize: UiFont.compact,
                    ),
                  )
                : Icon(
                    icon,
                    size: iconSize,
                    color: foregroundColor,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal group of square icon/text toggle options.
class CentrodeSquareGroup<T> extends StatelessWidget {
  final List<CentrodeSquareOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double itemSize;
  final double iconSize;

  const CentrodeSquareGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
    this.itemSize = UiControlSize.dense,
    this.iconSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(right: 3.0),
          child: CentrodeSquareToggle(
            isActive: opt.value == selectedValue,
            icon: opt.icon,
            label: opt.label,
            labelStyle: opt.labelStyle,
            tooltip: opt.tooltip,
            onTap: () => onSelected(opt.value),
            activeColor: activeColor,
            height: itemSize,
            width: itemSize,
            iconSize: iconSize,
          ),
        );
      }).toList(),
    );
  }
}
