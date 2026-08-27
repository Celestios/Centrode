import 'package:flutter/material.dart';

class SquareIconOption<T> {
  final T value;
  final IconData icon;
  final String tooltip;

  const SquareIconOption({
    required this.value,
    required this.icon,
    required this.tooltip,
  });
}

/// Compact horizontal row of square icon buttons taking minimal space.
class SquareIconGroup<T> extends StatelessWidget {
  final List<SquareIconOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const SquareIconGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final isSelected = opt.value == selectedValue;
        return Padding(
          padding: const EdgeInsets.only(right: 3.0),
          child: Tooltip(
            message: opt.tooltip,
            child: GestureDetector(
              onTap: () => onSelected(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    opt.icon,
                    size: 13,
                    color: isSelected
                        ? activeColor
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Standalone square toggle button for binary toggles (Bold, Italic, Strikethrough, etc.).
class SquareToggleButton extends StatelessWidget {
  final bool isActive;
  final IconData? icon;
  final String? label;
  final TextStyle? labelStyle;
  final String tooltip;
  final VoidCallback onTap;
  final Color activeColor;
  final double height;
  final double? width;

  const SquareToggleButton({
    super.key,
    required this.isActive,
    this.icon,
    this.label,
    this.labelStyle,
    required this.tooltip,
    required this.onTap,
    required this.activeColor,
    this.height = 30.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = isActive
        ? activeColor
        : (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ?? Colors.white70);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: (labelStyle ?? const TextStyle()).copyWith(
                      color: foregroundColor,
                      fontSize: 12.0,
                    ),
                  )
                : Icon(
                    icon,
                    size: 14,
                    color: foregroundColor,
                  ),
          ),
        ),
      ),
    );
  }
}

