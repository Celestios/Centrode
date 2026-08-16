import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/models.dart';

Color getContainerBaseColor(ContainerUiNode node, NodeStyle resolvedStyle) {
  if (resolvedStyle.strokeColor != 0 && resolvedStyle.strokeColor != 0xFF000000) {
    return Color(resolvedStyle.strokeColor);
  }
  if (resolvedStyle.bgColor != 0 && resolvedStyle.bgColor != 0x00000000) {
    return Color(resolvedStyle.bgColor).withValues(alpha: 1.0);
  }
  return const Color(0xFF64B5F6);
}

void drawDashedRRect(
  Canvas canvas,
  RRect rrect,
  Paint paint, [
  double dashWidth = 12.0,
  double dashSpace = 8.0,
]) {
  final path = Path()..addRRect(rrect);
  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < metric.length) {
      final double len = math.min(dashWidth, metric.length - distance);
      canvas.drawPath(metric.extractPath(distance, distance + len), paint);
      distance += dashWidth + dashSpace;
    }
  }
}

void paintContainerTopLeftTag(
  Canvas canvas,
  Rect rect,
  double scale,
  Color containerColor, {
  double opacity = 1.0,
}) {
  if (opacity <= 0.0) return;
  final hsl = HSLColor.fromColor(containerColor);
  final badgeTextColor = hsl
      .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
      .withLightness((hsl.lightness + 0.3).clamp(0.0, 0.95))
      .toColor()
      .withValues(alpha: opacity);
  final badgeBgColor = hsl
      .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
      .withLightness(0.12)
      .toColor()
      .withValues(alpha: 0.85 * opacity);

  final tagSpan = TextSpan(
    text: ' CONTAINER ',
    style: TextStyle(
      color: badgeTextColor,
      fontSize: (10.0 * scale).clamp(9.0, 13.0),
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
    ),
  );
  final tp = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)
    ..layout();

  final borderWidth = 2.0 * scale;
  final tagBg = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      rect.left + 12 * scale - borderWidth / 2,
      rect.top + 12 * scale - borderWidth / 2,
      tp.width + 12 * scale,
      tp.height + 6 * scale,
    ),
    Radius.circular(4.0 * scale),
  );
  canvas.drawRRect(tagBg, Paint()..color = badgeBgColor);
  canvas.drawRRect(
    tagBg,
    Paint()
      ..color = containerColor.withValues(alpha: 0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );
  tp.paint(
    canvas,
    Offset(
      rect.left + 18 * scale - borderWidth / 2,
      rect.top + 15 * scale - borderWidth / 2,
    ),
  );
  tp.dispose();
}
