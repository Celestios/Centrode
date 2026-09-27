import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

class CompactSliderBox extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final Color activeColor;
  final Color? activeSecondaryColor;
  final List<Color>? gradientColors;
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
    this.activeSecondaryColor,
    this.gradientColors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final clampedValue = value.clamp(min, max);
    final isInt = clampedValue == clampedValue.roundToDouble() || unit == '%';
    final formattedValue = isInt
        ? '${clampedValue.round()}$unit'
        : '${clampedValue.toStringAsFixed(1)}$unit';

    return Column(
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
                  fontSize: UiFont.micro,
                  fontWeight: FontWeight.w500,
                  color: palette.surface.controlForeground.withValues(alpha: 0.70),
                ),
              ),
            ),
            const SizedBox(width: UiSpacing.tight),
            Text(
              formattedValue,
              style: TextStyle(
                fontSize: UiFont.micro,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        CentrodeCompactSlider(
          value: clampedValue,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          activeSecondaryColor: activeSecondaryColor,
          gradientColors: gradientColors,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
