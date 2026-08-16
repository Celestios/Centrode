import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../utils/container_paint_utils.dart';

class ContainerBoundaryPainter extends CustomPainter {
  final ContainerUiNode? container;
  final Size effectiveSize;

  ContainerBoundaryPainter({
    required this.container,
    required this.effectiveSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final aspectRatio = effectiveSize.width > 0
        ? effectiveSize.height / effectiveSize.width
        : (1200.0 / 1600.0);
    final internalSize = Size(1600.0, 1600.0 * aspectRatio);
    final rect = Rect.fromLTWH(0, 0, internalSize.width, internalSize.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16.0));

    final baseColor = container != null && container!.resolvedStyle != null
        ? getContainerBaseColor(container!, container!.resolvedStyle!)
        : const Color(0xFF64B5F6);

    final hsl = HSLColor.fromColor(baseColor);
    final borderColor = hsl
        .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.4, 0.75))
        .toColor()
        .withValues(alpha: 0.85);
    final bgColor = hsl
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.08);

    // Background tint
    canvas.drawRRect(rrect, Paint()..color = bgColor..style = PaintingStyle.fill);

    // Dashed border (crisp 2px)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    drawDashedRRect(canvas, rrect, borderPaint, 16.0, 10.0);

    paintContainerTopLeftTag(canvas, rect, 1.0, baseColor, opacity: 1.0);
  }

  @override
  bool shouldRepaint(covariant ContainerBoundaryPainter oldDelegate) {
    return oldDelegate.container != container;
  }
}
