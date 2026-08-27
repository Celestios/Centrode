import 'package:flutter/material.dart';

/// Pattern C: Inline Value & Swatch Row combining label, swatch, and micro slider.
class InlinePropertyRow extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;
  final Color? colorSwatch;
  final Color activeColor;

  const InlinePropertyRow({
    super.key,
    this.label = '',
    this.leadingIcon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = 'px',
    this.colorSwatch,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = unit == 'x'
        ? '${value.toStringAsFixed(1)}x'
        : (unit.isEmpty
            ? value.toStringAsFixed(1)
            : '${value.toStringAsFixed(1)} $unit');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            SizedBox(
              width: 18,
              child: Icon(
                leadingIcon,
                size: 15,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? Colors.white54,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (label.isNotEmpty) ...[
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
          ],
          if (colorSwatch != null) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: colorSwatch,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
                activeTrackColor: activeColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: activeColor,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ?? Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
