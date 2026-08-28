import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Ultra-compact, micro slider box for high-density forms and inspector sub-blocks.
class CentrodeCompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const CentrodeCompactSlider({
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
      padding: const EdgeInsets.only(
        left: UiSpacing.tight,
        right: UiSpacing.tight,
        top: UiSpacing.tight,
        bottom: UiSpacing.tight,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(UiRadius.control),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: UiStrokeWidth.subtle,
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
                    fontSize: UiFont.micro,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.65) ??
                        Colors.white70,
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
          const SizedBox(height: UiSpacing.tight),
          SizedBox(
            height: 16,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: UiStrokeWidth.thick,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: UiRadius.control,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: UiRadius.control,
                ),
                activeTrackColor: activeColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: activeColor,
                trackShape: const CentrodeCompactTrackShape(),
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

class CentrodeCompactTrackShape extends RoundedRectSliderTrackShape {
  const CentrodeCompactTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? UiStrokeWidth.thick;
    final trackLeft = offset.dx + UiSpacing.tight;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - UiSpacing.standard;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
