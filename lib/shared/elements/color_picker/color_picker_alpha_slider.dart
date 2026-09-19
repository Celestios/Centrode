import 'package:flutter/material.dart';
import 'picker_color_model.dart';
import 'base_color_slider.dart';

/// Alpha slider (0–1). Horizontal drag sets the alpha.
class ColorPickerAlphaSlider extends StatelessWidget {
  final PickerColorModel model;

  const ColorPickerAlphaSlider({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final baseOpaque = model.hsvColor.toColor();
    return BaseColorSlider(
      value: model.alpha,
      onChanged: (v) => model.setAlpha(v),
      gradient: LinearGradient(
        colors: [
          baseOpaque.withValues(alpha: 0.0),
          baseOpaque.withValues(alpha: 1.0),
        ],
      ),
    );
  }
}
