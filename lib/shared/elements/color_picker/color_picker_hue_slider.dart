import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'picker_color_model.dart';

/// Horizontal hue spectrum painter (0–360°).
class HuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stops = [0.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0];
    final colors = stops.map((h) => HSVColor.fromAHSV(1.0, h, 1.0, 1.0).toColor()).toList();
    final grad = LinearGradient(
      colors: colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hue slider (0–360°). Horizontal drag sets the hue.
class ColorPickerHueSlider extends StatelessWidget {
  final PickerColorModel model;
  final Color borderSubtle;

  const ColorPickerHueSlider({
    super.key,
    required this.model,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 12.0;
        final hue = model.hsvColor.hue;
        return GestureDetector(
          onPanDown: (d) => model.setHue((d.localPosition.dx / width) * 360.0),
          onPanUpdate: (d) => model.setHue((d.localPosition.dx / width) * 360.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.pill),
              border: Border.all(color: borderSubtle, width: UiStrokeWidth.subtle),
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
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (hue / 360.0) * width - 6,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 2),
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
