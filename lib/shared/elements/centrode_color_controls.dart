import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

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
    required this.color,
    this.isNone = false,
    this.size = UiIconSize.dense,
    this.isSelected = false,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNone ? Colors.transparent : (color ?? Colors.white),
        border: Border.all(
          color: isSelected
              ? (selectedBorderColor ?? Colors.white)
              : (isNone ? Colors.white38 : Colors.white24),
          width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.standard,
        ),
      ),
      child: isNone
          ? Center(
              child: Icon(
                Icons.block_rounded,
                size: size * 0.7,
                color: Colors.white60,
              ),
            )
          : null,
    );
  }
}

/// Frosted glass color pill button displaying a color dot + label with popup options.
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
    final theme = Theme.of(context);
    final currentOpt = options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => options.first,
    );

    return PopupMenuButton<T>(
      tooltip: '$label: ${currentOpt.label}',
      color: const Color(0xFF151820),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.card),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
          width: UiStrokeWidth.subtle,
        ),
      ),
      offset: const Offset(0, 34),
      onSelected: onSelected,
      itemBuilder: (context) {
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
                        : Colors.white.withValues(alpha: 0.85),
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
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
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
                  color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.75) ??
                      Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
