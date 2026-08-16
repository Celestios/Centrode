import 'package:flutter/material.dart';
import '../../../models/models.dart';
import 'dashed_box_paint_utils.dart';

export 'dashed_box_paint_utils.dart';

Color getDashedBoxBaseColor(NodeStyle resolvedStyle, Color defaultColor) {
  if (resolvedStyle.strokeColor != 0 && resolvedStyle.strokeColor != 0xFF000000) {
    return Color(resolvedStyle.strokeColor);
  }
  if (resolvedStyle.bgColor != 0 && resolvedStyle.bgColor != 0x00000000) {
    return Color(resolvedStyle.bgColor).withValues(alpha: 1.0);
  }
  return defaultColor;
}

Color getContainerBaseColor(ContainerUiNode node, NodeStyle resolvedStyle) =>
    getDashedBoxBaseColor(resolvedStyle, const Color(0xFF64B5F6));

void paintContainerTopLeftTag(
  Canvas canvas,
  Rect rect,
  double scale,
  Color containerColor, {
  double opacity = 1.0,
}) {
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

  DashedBoxPaintUtils.paintTopLeftBadge(
    canvas,
    rect,
    scale,
    text: 'CONTAINER',
    textColor: badgeTextColor,
    badgeBgColor: badgeBgColor,
    borderColor: containerColor.withValues(alpha: 0.6 * opacity),
    opacity: opacity,
  );
}
