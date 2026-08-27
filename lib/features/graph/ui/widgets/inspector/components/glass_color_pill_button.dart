import 'package:flutter/material.dart';

class ColorPillOption<T> {
  final T value;
  final Color? color;
  final String label;
  final bool isNone;

  const ColorPillOption({
    required this.value,
    this.color,
    required this.label,
    this.isNone = false,
  });
}

/// A flat, full-width glass pill button displaying a circular color swatch indicator + label.
class GlassColorPillButton<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<ColorPillOption<T>> options;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const GlassColorPillButton({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.activeColor,
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
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
      ),
      offset: const Offset(0, 34),
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((opt) {
          final isSel = opt.value == selectedValue;
          return PopupMenuItem<T>(
            value: opt.value,
            height: 30,
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
                      width: 1,
                    ),
                  ),
                  child: opt.isNone
                      ? const Center(child: Icon(Icons.block_rounded, size: 10, color: Colors.white60))
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? activeColor : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentOpt.isNone ? Colors.transparent : (currentOpt.color ?? Colors.white),
                border: Border.all(
                  color: currentOpt.isNone
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.25),
                  width: currentOpt.isNone ? 1.0 : 0.8,
                ),
              ),
              child: currentOpt.isNone
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ?? Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
