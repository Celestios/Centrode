import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_surface_derivation.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

/// Minimal anchor contract decoupling shared palette derivation from concrete presentation themes.
abstract interface class ThemeAnchorPaletteSource {
  Color get primaryColor;
  Color get secondaryColor;
  Color get tertiaryColor;
  Color get accentColor;
  Color get canvasAccentColor;
  Brightness get brightness;
}

/// In-memory holder of the 5 chromatic anchors.
class ThemeAnchorPaletteValues implements ThemeAnchorPaletteSource {
  @override
  final Color primaryColor;
  @override
  final Color secondaryColor;
  @override
  final Color tertiaryColor;
  @override
  final Color accentColor;
  @override
  final Color canvasAccentColor;
  @override
  final Brightness brightness;

  const ThemeAnchorPaletteValues({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.accentColor,
    required this.canvasAccentColor,
    this.brightness = Brightness.dark,
  });
}

/// Semantic node tint colors derived dynamically from the theme.
@immutable
class NodeTintColors {
  final Color info;
  final Color task;
  final Color comment;
  final Color drawing;
  final Color shape;
  final Color frame;
  final Color container;
  final Color media;
  final Color inter;

  const NodeTintColors({
    required this.info,
    required this.task,
    required this.comment,
    required this.drawing,
    required this.shape,
    required this.frame,
    required this.container,
    required this.media,
    required this.inter,
  });

  factory NodeTintColors.fromSource(ThemeAnchorPaletteSource theme) {
    final primMono = ColorTheoryEngine.generateMonochromatic(theme.primaryColor, count: 5);

    return NodeTintColors(
      info: theme.primaryColor,
      task: theme.tertiaryColor,
      comment: primMono[1],
      drawing: theme.accentColor,
      shape: ColorTheoryEngine.shiftHue(theme.accentColor, 35),
      frame: theme.secondaryColor,
      container: theme.canvasAccentColor,
      media: ColorTheoryEngine.shiftHue(theme.canvasAccentColor, 25),
      inter: ColorTheoryEngine.shiftHue(theme.secondaryColor, -30),
    );
  }

  factory NodeTintColors.fromTheme(ThemeAnchorPaletteSource theme) => NodeTintColors.fromSource(theme);
}

/// Canvas rendering and interaction colors derived dynamically from the theme.
@immutable
class CanvasColors {
  final Color selectionBorder;
  final Color selectionFill;
  final Color containerBorder;
  final Color frameBorder;
  final Color nodeHover;
  final Color portIndicator;
  final Color portIndicatorActive;
  final Color connectionLine;
  final Color connectionLineActive;
  final Color miniMapLens;
  final Color miniMapLensBorder;

  const CanvasColors({
    required this.selectionBorder,
    required this.selectionFill,
    required this.containerBorder,
    required this.frameBorder,
    required this.nodeHover,
    required this.portIndicator,
    required this.portIndicatorActive,
    required this.connectionLine,
    required this.connectionLineActive,
    required this.miniMapLens,
    required this.miniMapLensBorder,
  });

  factory CanvasColors.fromSource(ThemeAnchorPaletteSource theme) {
    return CanvasColors(
      selectionBorder: theme.primaryColor,
      selectionFill: theme.primaryColor.withValues(alpha: UiAlpha.tint),
      containerBorder: theme.canvasAccentColor,
      frameBorder: theme.tertiaryColor,
      nodeHover: theme.primaryColor.withValues(alpha: UiAlpha.subtle),
      portIndicator: theme.canvasAccentColor,
      portIndicatorActive: theme.accentColor,
      connectionLine: theme.canvasAccentColor.withValues(alpha: UiAlpha.muted),
      connectionLineActive: theme.primaryColor,
      miniMapLens: theme.primaryColor.withValues(alpha: UiAlpha.medium),
      miniMapLensBorder: theme.primaryColor,
    );
  }

  factory CanvasColors.fromTheme(ThemeAnchorPaletteSource theme) => CanvasColors.fromSource(theme);
}

/// Status and feedback semantic colors derived dynamically from the theme.
@immutable
class SemanticColors {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  factory SemanticColors.fromSource(ThemeAnchorPaletteSource theme) {
    return SemanticColors(
      success: const Color(0xFF10B981),
      warning: theme.tertiaryColor,
      danger: theme.accentColor,
      info: theme.primaryColor,
    );
  }

  factory SemanticColors.fromTheme(ThemeAnchorPaletteSource theme) => SemanticColors.fromSource(theme);
}

/// Surfaces, card elevations, and border framing colors derived from the theme.
@immutable
class SurfaceColors {
  final Color panelBackground;
  final Color workspaceBackground;
  final Color cardBackground;
  final Color dialogBackground;
  final Color controlBackground;
  final Color subtleBackground;
  final Color controlForeground;
  final Color controlBorder;
  final Color controlBorderStrong;
  final Color borderSubtle;
  final Color borderStrong;

  const SurfaceColors({
    required this.panelBackground,
    required this.workspaceBackground,
    required this.cardBackground,
    required this.dialogBackground,
    required this.controlBackground,
    required this.subtleBackground,
    required this.controlForeground,
    required this.controlBorder,
    required this.controlBorderStrong,
    required this.borderSubtle,
    required this.borderStrong,
  });

  factory SurfaceColors.fromSource(ThemeAnchorPaletteSource theme) {
    final isDark = theme.brightness == Brightness.dark;
    final surfaces = ThemeSurfaceDerivation.deriveThemeSurfaces(
      primary: theme.primaryColor,
      secondary: theme.secondaryColor,
      tertiary: theme.tertiaryColor,
      anchors: [
        theme.primaryColor,
        theme.secondaryColor,
        theme.tertiaryColor,
        theme.accentColor,
        theme.canvasAccentColor,
      ],
      explicitBrightness: theme.brightness,
    );

    final controlFg = ColorTheoryEngine.bestContrastingTextColor(surfaces.control);

    return SurfaceColors(
      panelBackground: surfaces.panel,
      workspaceBackground: surfaces.workspaceBackground,
      cardBackground: surfaces.card,
      dialogBackground: surfaces.scaffoldBackground,
      controlBackground: surfaces.control,
      subtleBackground: surfaces.subtleSurface,
      controlForeground: controlFg,
      controlBorder: controlFg.withValues(alpha: isDark ? 0.08 : 0.12),
      controlBorderStrong: controlFg.withValues(alpha: isDark ? 0.18 : 0.22),
      borderSubtle: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      borderStrong: isDark
          ? Colors.white.withValues(alpha: 0.22)
          : Colors.black.withValues(alpha: 0.16),
    );
  }

  factory SurfaceColors.fromTheme(ThemeAnchorPaletteSource theme) => SurfaceColors.fromSource(theme);
}

/// Centralized dynamic alpha & opacity configuration for Centrode.
@immutable
class AlphaSettings {
  final double micro;
  final double hover;
  final double wash;
  final double tint;
  final double selectionFill;
  final double containerFill;
  final double frameFill;
  final double miniMapLens;
  final double connectionLine;
  final double borderSubtle;
  final double borderStrong;
  final double textMuted;
  final double textSecondary;
  final double glassBody;
  final double glassHeader;

  const AlphaSettings({
    this.micro = UiAlpha.micro,
    this.hover = UiAlpha.subtle,
    this.wash = UiAlpha.wash,
    this.tint = UiAlpha.tint,
    this.selectionFill = UiAlpha.tint,
    this.containerFill = UiAlpha.wash,
    this.frameFill = UiAlpha.subtle,
    this.miniMapLens = UiAlpha.medium,
    this.connectionLine = UiAlpha.muted,
    this.borderSubtle = UiAlpha.borderSubtle,
    this.borderStrong = UiAlpha.borderStrong,
    this.textMuted = UiAlpha.half,
    this.textSecondary = UiAlpha.muted,
    this.glassBody = UiAlpha.glassBody,
    this.glassHeader = UiAlpha.glassHeader,
  });
}

/// Centralized dynamic color palette derived algorithmically from the active [AppTheme].
@immutable
class CentrodeDerivedPalette {
  /// The underlying theme this palette was derived from (if available).
  final ThemeAnchorPaletteSource? theme;

  /// Centralized alpha and opacity parameters.
  final AlphaSettings alpha;

  /// The 12 canonical swatches derived from the theme's anchor colors.
  final List<Color> swatches;

  /// 5 Distinct tag colors derived harmonically from the accents.
  final List<Color> tagColors;

  /// Node type tint colors.
  final NodeTintColors nodeTints;

  /// Canvas interaction and rendering colors.
  final CanvasColors canvas;

  /// Semantic feedback colors.
  final SemanticColors semantic;

  /// Neutral opaque surface and border colors.
  final SurfaceColors surface;

  /// 5 Analogous harmony colors derived from the primary color.
  final List<Color> primaryAnalogous;

  /// 5 Complementary harmony colors derived from the primary color.
  final List<Color> primaryComplementary;

  /// 5 Triadic harmony colors derived from the primary color.
  final List<Color> primaryTriadic;

  /// 5 Monochromatic shades derived from the primary color.
  final List<Color> primaryMonochromatic;

  const CentrodeDerivedPalette._({
    this.theme,
    this.alpha = const AlphaSettings(),
    required this.swatches,
    required this.tagColors,
    required this.nodeTints,
    required this.canvas,
    required this.semantic,
    required this.surface,
    required this.primaryAnalogous,
    required this.primaryComplementary,
    required this.primaryTriadic,
    required this.primaryMonochromatic,
  });

  /// Factory constructing the derived palette directly from a [ThemeAnchorPaletteSource].
  factory CentrodeDerivedPalette.fromSource(ThemeAnchorPaletteSource theme) {
    final swatches = ColorTheoryEngine.deriveThemePalette(
      primary: theme.primaryColor,
      accent: theme.accentColor,
      canvasAccent: theme.canvasAccentColor,
    );

    final tagColors = [
      theme.primaryColor,
      theme.secondaryColor,
      theme.tertiaryColor,
      theme.accentColor,
      theme.canvasAccentColor,
    ];

    return CentrodeDerivedPalette._(
      theme: theme,
      alpha: const AlphaSettings(),
      swatches: swatches,
      tagColors: tagColors,
      nodeTints: NodeTintColors.fromSource(theme),
      canvas: CanvasColors.fromSource(theme),
      semantic: SemanticColors.fromSource(theme),
      surface: SurfaceColors.fromSource(theme),
      primaryAnalogous: ColorTheoryEngine.generateAnalogous(theme.primaryColor),
      primaryComplementary: ColorTheoryEngine.generateComplementary(theme.primaryColor),
      primaryTriadic: ColorTheoryEngine.generateTriadic(theme.primaryColor),
      primaryMonochromatic: ColorTheoryEngine.generateMonochromatic(theme.primaryColor),
    );
  }

  /// Alias preserving API compatibility for theme consumers.
  factory CentrodeDerivedPalette.fromTheme(ThemeAnchorPaletteSource theme) =>
      CentrodeDerivedPalette.fromSource(theme);

  /// Factory constructing the derived palette from raw anchor colors.
  factory CentrodeDerivedPalette.fromColors({
    required Color primary,
    required Color accent,
    required Color canvasAccent,
    Color? secondary,
    Color? tertiary,
    Brightness brightness = Brightness.dark,
  }) {
    final secColor = secondary ?? ColorTheoryEngine.shiftHue(primary, 180);
    final tertColor = tertiary ?? ColorTheoryEngine.shiftHue(primary, 120);

    return CentrodeDerivedPalette.fromSource(
      ThemeAnchorPaletteValues(
        primaryColor: primary,
        secondaryColor: secColor,
        tertiaryColor: tertColor,
        accentColor: accent,
        canvasAccentColor: canvasAccent,
        brightness: brightness,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Color & Alpha Helpers
  // ---------------------------------------------------------------------------

  /// Subtle border outline (glass rims, sub-blocks), derived from tertiaryColor (borders).
  Color get borderSubtle => surface.borderSubtle;

  /// Strong border outline (card elevation, modals), derived from tertiaryColor (borders).
  Color get borderStrong => surface.borderStrong;

  /// Focus outline on active controls.
  Color get borderFocus => theme?.primaryColor ?? swatches[0];

  /// Hover overlay wash on interactive elements.
  Color get hoverOverlay => (theme?.primaryColor ?? swatches[0]).withValues(alpha: alpha.hover);

  /// Active pressed overlay on interactive elements.
  Color get activeOverlay => (theme?.primaryColor ?? swatches[0]).withValues(alpha: alpha.selectionFill);

  /// Returns a soft wash / tint of [color] using the centralized tint alpha.
  Color tint(Color color, [double? targetAlpha]) =>
      color.withValues(alpha: targetAlpha ?? alpha.tint);

  /// Returns a subtle hover overlay of [color].
  Color hover(Color color) => color.withValues(alpha: alpha.hover);

  /// Returns a border outline color with standardized subtle or strong alpha.
  Color border(Color color, {bool strong = false}) =>
      color.withValues(alpha: strong ? alpha.borderStrong : alpha.borderSubtle);

  /// Returns a muted label / icon color.
  Color mutedText(Color color) => color.withValues(alpha: alpha.textMuted);

  /// Returns secondary label color.
  Color secondaryText(Color color) => color.withValues(alpha: alpha.textSecondary);

  /// Returns glass background fill with dynamic header or body alpha.
  Color glassBackground({bool isHeader = false}) =>
      surface.cardBackground.withValues(alpha: isHeader ? alpha.glassHeader : alpha.glassBody);

  /// Returns the smart WCAG AAA contrasting text color for any arbitrary background surface.
  Color textOn(Color background) => ColorTheoryEngine.bestContrastingTextColor(background);

  /// Returns muted contrasting text color for any arbitrary background surface.
  Color mutedTextOn(Color background) =>
      ColorTheoryEngine.bestContrastingTextColor(background).withValues(alpha: alpha.textMuted);

  static CentrodeDerivedPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<CentrodeThemeExtension>();
    if (ext != null) return ext.palette;

    final materialTheme = Theme.of(context);
    return CentrodeDerivedPalette.fromColors(
      primary: materialTheme.colorScheme.primary,
      secondary: materialTheme.colorScheme.secondary,
      tertiary: materialTheme.colorScheme.tertiary,
      accent: materialTheme.colorScheme.secondary,
      canvasAccent: materialTheme.colorScheme.primary,
      brightness: materialTheme.brightness,
    );
  }
}

/// ThemeExtension delivering [CentrodeDerivedPalette] down the widget tree.
@immutable
class CentrodeThemeExtension extends ThemeExtension<CentrodeThemeExtension> {
  final CentrodeDerivedPalette palette;

  const CentrodeThemeExtension({
    required this.palette,
  });

  @override
  CentrodeThemeExtension copyWith({
    CentrodeDerivedPalette? palette,
  }) {
    return CentrodeThemeExtension(
      palette: palette ?? this.palette,
    );
  }

  @override
  CentrodeThemeExtension lerp(ThemeExtension<CentrodeThemeExtension>? other, double t) {
    if (other is! CentrodeThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}
