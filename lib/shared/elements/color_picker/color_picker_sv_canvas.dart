import 'package:flutter/material.dart';
import 'picker_color_model.dart';
import 'saturation_value_painter.dart';

/// Saturation/value canvas: horizontal = saturation, vertical = value.
class ColorPickerSvCanvas extends StatelessWidget {
  final PickerColorModel model;
  final Color borderSubtle;

  const ColorPickerSvCanvas({
    super.key,
    required this.model,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 135.0;
        final hsv = model.hsvColor;
        return GestureDetector(
          onPanDown: (d) => model.setSaturationValue(
            d.localPosition.dx / width,
            1.0 - d.localPosition.dy / height,
          ),
          onPanUpdate: (d) => model.setSaturationValue(
            d.localPosition.dx / width,
            1.0 - d.localPosition.dy / height,
          ),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: borderSubtle),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      painter: SaturationValuePainter(hue: hsv.hue),
                      size: Size(width, height),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.saturation * width - 7,
                  top: (1.0 - hsv.value) * height - 7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 3),
                      ],
                    ),
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
