import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'glass_color_pill_button.dart';

/// Single compact square button that displays the active color/swatch with a palette dropdown menu.
class SquareSwatchButton<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<ColorPillOption<T>> options;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final bool showLabel;

  const SquareSwatchButton({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.activeColor,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentOpt = options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => options.first,
    );

    final button = PopupMenuButton<T>(
      tooltip: '$label: ${currentOpt.label}',
      color: const Color(0xFF151820),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.card),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: UiStrokeWidth.subtle),
      ),
      offset: const Offset(0, 30),
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((opt) {
          final isSel = opt.value == selectedValue;
          return PopupMenuItem<T>(
            value: opt.value,
            height: UiControlSize.standard,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: opt.isNone ? Colors.transparent : (opt.color ?? Colors.white),
                    border: Border.all(
                      color: opt.isNone ? Colors.white38 : Colors.white24,
                      width: UiStrokeWidth.standard,
                    ),
                  ),
                  child: opt.isNone
                      ? const Center(child: Icon(Icons.block_rounded, size: 10, color: Colors.white60))
                      : null,
                ),
                const SizedBox(width: UiSpacing.standard),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: UiFont.compact,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? activeColor : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: AnimatedContainer(
        duration: UiMotion.fast,
        width: 26,
        height: UiControlSize.dense,
        decoration: BoxDecoration(
          color: currentOpt.isNone ? Colors.black.withValues(alpha: 0.35) : (currentOpt.color ?? Colors.white),
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: UiStrokeWidth.standard,
          ),
          boxShadow: !currentOpt.isNone && currentOpt.color != null
              ? [
                  BoxShadow(
                    color: currentOpt.color!.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: currentOpt.isNone
            ? const Center(
                child: Icon(Icons.block_rounded, size: 12, color: Colors.white54),
              )
            : null,
      ),
    );

    if (!showLabel || label.isEmpty) {
      return button;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: UiFont.compact,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 5),
        button,
      ],
    );
  }
}
