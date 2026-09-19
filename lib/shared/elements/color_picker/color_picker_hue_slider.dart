import 'package:flutter/material.dart';
import 'picker_color_model.dart';
import 'base_color_slider.dart';

/// Hue slider (0–360°). Horizontal drag sets the hue.
class ColorPickerHueSlider extends StatelessWidget {
  final PickerColorModel model;

  const ColorPickerHueSlider({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return BaseColorSlider(
      value: model.hsvColor.hue / 360.0,
      onChanged: (v) => model.setHue(v * 360.0),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ),
    );
  }
}
