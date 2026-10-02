import 'package:flutter/material.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

/// Derives application shell surfaces, boundaries, controls, and text
/// dynamically from the 5 chromatic theme anchors using OKLCH perceptual space.
abstract final class ThemeSurfaceDerivation {
  /// Standardized Perceptual OKLCH Optical Elevation Steps
  static const double elevationStep = 0.04;
  static const double microElevationStep = 0.025;
  static const double recessedStep = 0.05;

  /// Intelligently derives whether a palette of chromatic anchors belongs to a Dark or Light theme.
  /// The secondary anchor is the background surface. Its perceptual luminance directly dictates theme brightness.
  static Brightness deriveBrightness(List<Color> anchors) {
    if (anchors.isEmpty) return Brightness.dark;
    final background = anchors.length > 1 ? anchors[1] : anchors[0];
    return (ColorTheoryEngine.relativeLuminance(background) < 0.40) ? Brightness.dark : Brightness.light;
  }

  /// Derives harmonious surfaces, boundaries, text, and brightness
  /// strictly from the chromatic anchors:
  /// - [primary]: Active elements & focus
  /// - [secondary]: Background canvas base
  /// - [tertiary]: Borders & boundaries
  static ({
    Brightness brightness,
    Color scaffoldBackground,
    Color workspaceBackground,
    Color panel,
    Color card,
    Color divider,
    Color text,
    Color control,
    Color subtleSurface,
    Color appBarBackground,
    Color appBarForeground,
  }) deriveThemeSurfaces({
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required List<Color> anchors,
    Brightness? explicitBrightness,
  }) {
    final brightness = explicitBrightness ?? deriveBrightness(anchors);
    final isDark = brightness == Brightness.dark;
    final scaffold = secondary;
    final polarity = isDark ? -1.0 : 1.0;
    final secOklch = OklchColor.fromColor(secondary);

    // Main workspace area canvas:
    // In dark themes, the canvas is deeply grounded at 0.0 (ground zero).
    // In light themes, the canvas is grounded at (1.0 - elevationStep), leaving room
    // for floating cards to sit at 1.0, eliminating harsh glare while preserving theme undertone.
    final groundLightness = isDark ? 0.0 : (1.0 - 2 * elevationStep);
    final workspaceBackground = OklchColor(
      groundLightness,
      0.0,
      0.0,
    ).toColor();

    final primOklch = OklchColor.fromColor(primary);
    final panelLightness = isDark
        ? (secOklch.l * 0.85).clamp(0.06, 0.16)
        : (1.0 - 1.25 * elevationStep).clamp(0.0, 1.0);
    final panelChroma = isDark
        ? (primOklch.c * 0.22).clamp(0.015, 0.035)
        : (primOklch.c * 0.28).clamp(0.02, 0.045);
    final panel = primOklch.copyWith(
      l: panelLightness,
      c: panelChroma,
    ).toColor();

    // Stepped card / elevation surface:
    // Symmetrically elevated above the canvas ground:
    // In dark mode: elevated (+elevationStep) above the dark base.
    // In light mode: elevated to 1.0 (pure/near-pure white floating card).
    final cardLightness = isDark
        ? (secOklch.l + elevationStep).clamp(0.0, 1.0)
        : 0.94;
    final card = secOklch.copyWith(
      l: cardLightness,
      c: isDark ? secOklch.c : (secOklch.c * 0.15),
    ).toColor();

    // Symmetrical recessed (dark) or elevated (light) control/button surface:
    final controlLightness = (secOklch.l + (polarity * recessedStep)).clamp(0.01, 1.0);
    final control = secOklch.copyWith(l: controlLightness).toColor();

    // Subtle container background for nested sub-blocks and secondary placeholders:
    final subtleLightness = (secOklch.l + (polarity * microElevationStep)).clamp(0.01, 1.0);
    final subtleSurface = secOklch.copyWith(l: subtleLightness).toColor();

    // Guaranteed WCAG AAA text contrast against card surface
    final text = ColorTheoryEngine.bestContrastingTextColor(card);

    // Internal surface divider derived with distinct neutral contrast (different from borders)
    final divider = text.withValues(alpha: isDark ? 0.10 : 0.08);

    return (
      brightness: brightness,
      scaffoldBackground: scaffold,
      workspaceBackground: workspaceBackground,
      panel: panel,
      card: card,
      divider: divider,
      text: text,
      control: control,
      subtleSurface: subtleSurface,
      appBarBackground: scaffold,
      appBarForeground: text,
    );
  }
}
