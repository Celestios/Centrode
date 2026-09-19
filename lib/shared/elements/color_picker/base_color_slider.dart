import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

/// Shared horizontal pill slider used by hue and alpha color picker tracks.
///
/// Centralizes pointer tracking, gesture clamping, 12px pill layout, and
/// thumb offset math that was duplicated across hue and alpha sliders.
class BaseColorSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Gradient gradient;
  final BoxDecoration? thumbDecoration;

  const BaseColorSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.gradient,
    this.thumbDecoration,
  });

  static const double _trackHeight = 12.0;
  static const double _thumbRadius = 8.0;
  static const double _thumbDiameter = _thumbRadius * 2;
  static const double _thumbTopOffset = -2.0;

  BoxDecoration get _defaultThumbDecoration => const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: Colors.black26, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2)],
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final clampedWidth = width > 0 ? width : 1.0;
        return GestureDetector(
          onPanDown: (d) => onChanged((d.localPosition.dx / clampedWidth).clamp(0.0, 1.0)),
          onPanUpdate: (d) => onChanged((d.localPosition.dx / clampedWidth).clamp(0.0, 1.0)),
          child: Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.pill),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: UiStrokeWidth.subtle,
              ),
              gradient: gradient,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (value * width) - _thumbRadius,
                  top: _thumbTopOffset,
                  child: Container(
                    width: _thumbDiameter,
                    height: _thumbDiameter,
                    decoration: thumbDecoration ?? _defaultThumbDecoration,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
