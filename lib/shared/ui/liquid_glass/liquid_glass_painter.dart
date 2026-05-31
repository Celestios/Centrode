import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'liquid_glass_settings.dart';

class LiquidGlassFallbackPainter extends CustomPainter {
  final double borderRadius;
  final OCLiquidGlassSettings settings;
  final Color tintColor;

  LiquidGlassFallbackPainter({
    required this.borderRadius,
    required this.settings,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Simulated Refraction (Inner Shadow in bottom-right)
    canvas.save();
    canvas.clipRRect(rrect);

    // Draw a dark inner shadow gradient from bottom-right towards center
    final refractPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black.withValues(alpha: 0.18), Colors.transparent],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ).createShader(rect)
      ..blendMode = BlendMode.multiply;

    canvas.drawRRect(rrect, refractPaint);
    canvas.restore();

    // 2. Light Band (Rim Glow)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.lightbandWidthPx
      ..shader = LinearGradient(
        colors: [
          settings.lightbandColor.withValues(alpha: settings.lightbandStrength),
          settings.lightbandColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    // Adjust RRect for rim offset
    final offsetDistance = settings.lightbandOffsetPx;
    final rimRect = rect.deflate(offsetDistance);
    final rimRRect = RRect.fromRectAndRadius(
      rimRect,
      Radius.circular(math.max(0.0, borderRadius - offsetDistance)),
    );
    canvas.drawRRect(rimRRect, rimPaint);

    // 3. Specular Highlight (Top-left Glint)
    final specPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.8),
        radius: 0.6,
        colors: [
          Colors.white.withValues(alpha: settings.specStrength / 20.0),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, specPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassFallbackPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.settings != settings ||
        oldDelegate.tintColor != tintColor;
  }
}
