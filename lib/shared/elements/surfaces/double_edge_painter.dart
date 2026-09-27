import 'package:flutter/material.dart';

class CentrodeDoubleEdgePainter extends CustomPainter {
  final double cornerRadius;
  final double stepWidth;
  final double lightIntensity;

  const CentrodeDoubleEdgePainter({
    required this.cornerRadius,
    this.stepWidth = 2.0,
    this.lightIntensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final outerRect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(cornerRadius),
    );

    final innerRect = Rect.fromLTWH(
      stepWidth,
      stepWidth,
      (size.width - 2 * stepWidth).clamp(0.0, 9999.0),
      (size.height - 2 * stepWidth).clamp(0.0, 9999.0),
    );
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular((cornerRadius - stepWidth).clamp(0.0, 999.0)),
    );

    canvas.saveLayer(outerRect, Paint());
    canvas.clipRRect(outerRRect);

    final topShadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x38000000),
          Color(0x18000000),
          Color(0x00000000),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, stepWidth + 3.0));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, stepWidth + 3.0), topShadowPaint);

    final leftShadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x38000000),
          Color(0x18000000),
          Color(0x00000000),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, stepWidth + 3.0, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, stepWidth + 3.0, size.height), leftShadowPaint);

    canvas.drawRRect(innerRRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.saveLayer(outerRect, Paint());
    canvas.clipRRect(outerRRect);

    final brGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x00FFFFFF),
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, (0.20 * lightIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 255, 255, (0.55 * lightIntensity).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(outerRect);
    canvas.drawRect(outerRect, brGlowPaint);

    canvas.drawRRect(innerRRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final outerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromRGBO(255, 255, 255, (0.65 * lightIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 255, 255, (0.35 * lightIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 255, 255, (0.85 * lightIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 255, 255, (0.98 * lightIntensity).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(outerRect);
    canvas.drawRRect(outerRRect, outerStrokePaint);

    final innerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x28000000),
          const Color(0x10000000),
          Color.fromRGBO(255, 255, 255, (0.75 * lightIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 255, 255, (0.92 * lightIntensity).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect, innerStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CentrodeDoubleEdgePainter oldDelegate) =>
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.stepWidth != stepWidth ||
      oldDelegate.lightIntensity != lightIntensity;
}
