import 'dart:ui';
import 'package:flutter/painting.dart';

/// Centralized tokens for canvas rendering, dashed geometry, and approach zoom.
abstract final class CanvasPainterTokens {
  CanvasPainterTokens._();

  // --- Virtual Container Geometry ---
  static const double containerVirtualDimension = 1600.0;
  static const Size containerFallbackOuterSize = Size(300.0, 180.0);
  static const double containerApproachMinScreenWidth = 80.0;
  static const double containerApproachMaxScreenWidth = 180.0;
  static const double containerBorderRadius = 16.0;

  // --- Dash Patterns ---
  static const double dashedBoxDashWidth = 12.0;
  static const double dashedBoxDashSpace = 8.0;
  static const double frameDashWidth = 14.0;
  static const double frameDashSpace = 8.0;
  static const double containerDashWidth = 16.0;
  static const double containerDashSpace = 10.0;
  static const double relationDashWidth = 8.0;
  static const double relationDashSpace = 6.0;
  static const double relationDotWidth = 2.0;
  static const double relationDotSpace = 4.0;

  // --- Handles & Grip Geometry ---
  static const double sideHandleGripThickness = 5.0;
  static const double sideHandleGripLength = 22.0;
  static const double sideHandleCornerRadius = 2.5;
  static const double relationEndpointHandleOuterRadius = 6.0;
  static const double relationEndpointHandleInnerRadius = 5.0;
  static const double portHoverScaleMultiplier = 1.5;
  static const double portCrossArmFactor = 0.5;

  // --- Badges & Insets ---
  static const double badgeCornerRadius = 4.0;
  static const double badgeBorderWidth = 1.0;
  static const Offset badgeDefaultOffset = Offset(12.0, 12.0);
  static const double relationLabelPaddingX = 8.0;
  static const double relationLabelPaddingY = 4.0;
  static const double relationLabelRadius = 8.0;
  static const double relationLabelFontSize = 10.0;

  // --- Colors & Multipliers ---
  static const Color frameDefaultColor = Color(0xFFBCAAA4);
  static const Color containerDefaultColor = Color(0xFF64B5F6);
  static const double containerBorderSatMultiplier = 1.35;
  static const double containerBorderAlpha = 0.85;
  static const double containerBgSatMultiplier = 1.1;
  static const double containerBgAlpha = 0.08;
}

/// Reusable path manipulation and color derivation helpers for custom painters.
abstract final class PaintGeometry {
  PaintGeometry._();

  /// Unified dashed path generator for straight or curved Path objects.
  static Path createDashedPath(Path source, double dashLen, double gapLen) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLen : gapLen;
        if (draw) {
          dest.addPath(
            metric.extractPath(
              distance,
              (distance + len).clamp(0.0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  /// Unified HSL border & background derivation for container / grouping boxes.
  static ({Color border, Color background}) deriveBoxColors(
    Color baseColor, {
    double opacity = 1.0,
  }) {
    final hsl = HSLColor.fromColor(baseColor);
    final border = hsl
        .withSaturation(
          (hsl.saturation * CanvasPainterTokens.containerBorderSatMultiplier)
              .clamp(0.0, 1.0),
        )
        .withLightness(hsl.lightness.clamp(0.4, 0.75))
        .toColor()
        .withValues(
          alpha: CanvasPainterTokens.containerBorderAlpha * opacity,
        );
    final background = hsl
        .withSaturation(
          (hsl.saturation * CanvasPainterTokens.containerBgSatMultiplier)
              .clamp(0.0, 1.0),
        )
        .toColor()
        .withValues(
          alpha: CanvasPainterTokens.containerBgAlpha * opacity,
        );
    return (border: border, background: background);
  }
}
