import 'package:flutter/material.dart';

/// Ultra-compact, side-by-side micro slider box for high-density inspector sub-blocks.
class CompactSliderBox extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const CompactSliderBox({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unit = 'px',
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedValue = value.clamp(min, max);
    final isInt = clampedValue == clampedValue.roundToDouble() || unit == '%';
    final formattedValue = isInt
        ? '${clampedValue.round()}$unit'
        : '${clampedValue.toStringAsFixed(1)}$unit';

    return Container(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 4.0, bottom: 2.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65) ?? Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 16,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 6.0),
                activeTrackColor: activeColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: activeColor,
                trackShape: const _CompactTrackShape(),
              ),
              child: Slider(
                value: clampedValue,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTrackShape extends RoundedRectSliderTrackShape {
  const _CompactTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2.0;
    final trackLeft = offset.dx + 4.0;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 8.0;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
