import 'package:flutter/material.dart';

/// Paints the saturation/value checkerboard gradient for a fixed [hue].
class SaturationValuePainter extends CustomPainter {
  final double hue;

  const SaturationValuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final base = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    final horizontal = LinearGradient(
      colors: [Colors.white, base],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = horizontal.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final vertical = LinearGradient(
      colors: [Colors.transparent, Colors.black],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = vertical.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant SaturationValuePainter oldDelegate) => oldDelegate.hue != hue;
}
