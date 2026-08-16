import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Centralized, high-performance dashed geometry and badge rendering utilities
/// shared across Frame nodes, Container boundaries, and OptArea overlays.
class DashedBoxPaintUtils {
  const DashedBoxPaintUtils._();

  /// Draws a dashed rounded rectangle onto the [canvas].
  static void drawDashedRRect(
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

  /// Draws a standardized top-left header badge with rounded corners, subtle border,
  /// and uppercase tracking.
  static void paintTopLeftBadge(
    Canvas canvas,
    Rect rect,
    double scale, {
    required String text,
    required Color textColor,
    required Color badgeBgColor,
    Color? borderColor,
    double opacity = 1.0,
    Offset offset = const Offset(12.0, 12.0),
  }) {
    if (opacity <= 0.0 || text.trim().isEmpty) return;

    final formattedText = ' ${text.trim().toUpperCase()} ';
    final tagSpan = TextSpan(
      text: formattedText,
      style: TextStyle(
        color: textColor.withValues(alpha: opacity),
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
        rect.left + offset.dx * scale - borderWidth / 2,
        rect.top + offset.dy * scale - borderWidth / 2,
        tp.width + 12 * scale,
        tp.height + 6 * scale,
      ),
      Radius.circular(4.0 * scale),
    );

    canvas.drawRRect(tagBg, Paint()..color = badgeBgColor.withValues(alpha: badgeBgColor.a * opacity));

    if (borderColor != null) {
      canvas.drawRRect(
        tagBg,
        Paint()
          ..color = borderColor.withValues(alpha: borderColor.a * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    tp.paint(
      canvas,
      Offset(
        rect.left + (offset.dx + 6.0) * scale - borderWidth / 2,
        rect.top + (offset.dy + 3.0) * scale - borderWidth / 2,
      ),
    );
    tp.dispose();
  }

  /// Draws a standardized top-centered header badge placed outside/above the top edge of the rect.
  static void paintTopCenteredBadge(
    Canvas canvas,
    Rect rect,
    double scale, {
    required String text,
    required Color textColor,
    required Color badgeBgColor,
    Color? borderColor,
    double opacity = 1.0,
    double verticalOffset = -22.0,
  }) {
    if (opacity <= 0.0 || text.trim().isEmpty) return;

    final formattedText = ' ${text.trim().toUpperCase()} ';
    final tagSpan = TextSpan(
      text: formattedText,
      style: TextStyle(
        color: textColor.withValues(alpha: opacity),
        fontSize: (11.0 * scale).clamp(9.0, 14.0),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );

    final tp = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)
      ..layout();

    final badgeWidth = tp.width + 16 * scale;
    final badgeHeight = tp.height + 6 * scale;
    final badgeLeft = rect.center.dx - (badgeWidth / 2);
    final badgeTop = rect.top + verticalOffset * scale;

    final tagBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        badgeLeft,
        badgeTop,
        badgeWidth,
        badgeHeight,
      ),
      Radius.circular(4.0 * scale),
    );

    canvas.drawRRect(tagBg, Paint()..color = badgeBgColor.withValues(alpha: badgeBgColor.a * opacity));

    if (borderColor != null) {
      canvas.drawRRect(
        tagBg,
        Paint()
          ..color = borderColor.withValues(alpha: borderColor.a * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    tp.paint(
      canvas,
      Offset(
        badgeLeft + 8 * scale,
        badgeTop + 3 * scale,
      ),
    );
    tp.dispose();
  }

  /// Complete painting helper for a dashed container/frame box with background tint,
  /// dashed border, and optional header badge.
  static void paintDashedBox(
    Canvas canvas,
    Rect rect, {
    required Color baseColor,
    Color? borderColor,
    Color? bgColor,
    double borderRadius = 8.0,
    double strokeWidth = 1.5,
    double dashWidth = 12.0,
    double dashSpace = 8.0,
    String? badgeText,
    bool badgeCenteredOutside = false,
    bool showResizeHandles = false,
    double scale = 1.0,
    double opacity = 1.0,
    Offset badgeOffset = const Offset(12.0, 12.0),
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius * scale));
    final hsl = HSLColor.fromColor(baseColor);

    final effectiveBorderColor = borderColor ??
        hsl
            .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
            .withLightness(hsl.lightness.clamp(0.4, 0.75))
            .toColor()
            .withValues(alpha: 0.85 * opacity);

    final effectiveBgColor = bgColor ??
        hsl
            .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
            .toColor()
            .withValues(alpha: 0.02 * opacity);

    // 1. Subtle background tint
    if (effectiveBgColor.a > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = effectiveBgColor
          ..style = PaintingStyle.fill,
      );
    }

    // 2. Crisp dashed border
    final borderPaint = Paint()
      ..color = effectiveBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale;

    drawDashedRRect(canvas, rrect, borderPaint, dashWidth * scale, dashSpace * scale);

    // 3. Header badge
    if (badgeText != null && badgeText.isNotEmpty) {
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

      if (badgeCenteredOutside) {
        paintTopCenteredBadge(
          canvas,
          rect,
          scale,
          text: badgeText,
          textColor: badgeTextColor,
          badgeBgColor: badgeBgColor,
          borderColor: baseColor.withValues(alpha: 0.6 * opacity),
          opacity: opacity,
        );
      } else {
        paintTopLeftBadge(
          canvas,
          rect,
          scale,
          text: badgeText,
          textColor: badgeTextColor,
          badgeBgColor: badgeBgColor,
          borderColor: baseColor.withValues(alpha: 0.6 * opacity),
          opacity: opacity,
          offset: badgeOffset,
        );
      }
    }

    // 4. Side Resize Handles (Pill/Bar grips on left, right, top, bottom edges)
    if (showResizeHandles) {
      final handleFillPaint = Paint()
        ..color = effectiveBorderColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      final handleStrokePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 1.0 * scale
        ..style = PaintingStyle.stroke;

      // Left handle (vertical pill at center of left edge)
      final leftHandle = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.left, rect.center.dy),
          width: 5 * scale,
          height: 22 * scale,
        ),
        Radius.circular(2.5 * scale),
      );
      canvas.drawRRect(leftHandle, handleFillPaint);
      canvas.drawRRect(leftHandle, handleStrokePaint);

      // Right handle (vertical pill at center of right edge)
      final rightHandle = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.right, rect.center.dy),
          width: 5 * scale,
          height: 22 * scale,
        ),
        Radius.circular(2.5 * scale),
      );
      canvas.drawRRect(rightHandle, handleFillPaint);
      canvas.drawRRect(rightHandle, handleStrokePaint);

      // Top handle (horizontal pill at center of top edge)
      final topHandle = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top),
          width: 22 * scale,
          height: 5 * scale,
        ),
        Radius.circular(2.5 * scale),
      );
      canvas.drawRRect(topHandle, handleFillPaint);
      canvas.drawRRect(topHandle, handleStrokePaint);

      // Bottom handle (horizontal pill at center of bottom edge)
      final bottomHandle = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.bottom),
          width: 22 * scale,
          height: 5 * scale,
        ),
        Radius.circular(2.5 * scale),
      );
      canvas.drawRRect(bottomHandle, handleFillPaint);
      canvas.drawRRect(bottomHandle, handleStrokePaint);
    }
  }
}

/// Global top-level convenience helper for drawing dashed rounded rectangles.
void drawDashedRRect(
  Canvas canvas,
  RRect rrect,
  Paint paint, [
  double dashWidth = 12.0,
  double dashSpace = 8.0,
]) =>
    DashedBoxPaintUtils.drawDashedRRect(
      canvas,
      rrect,
      paint,
      dashWidth,
      dashSpace,
    );
