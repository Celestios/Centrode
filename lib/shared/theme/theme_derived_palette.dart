import 'package:flutter/material.dart';
import 'package:centrode/presentation/theme/app_theme.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

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

  factory NodeTintColors.fromTheme(AppTheme theme) {
    final primOklch = OklchColor.fromColor(theme.primaryColor);
    final accOklch = OklchColor.fromColor(theme.accentColor);
    final canOklch = OklchColor.fromColor(theme.canvasAccentColor);

    return NodeTintColors(
      info: primOklch.copyWith(l: 0.78, c: 0.12).toColor(),
      task: canOklch.copyWith(l: 0.76, c: 0.14).toColor(),
      comment: primOklch.copyWith(l: 0.72, c: 0.04).toColor(),
      drawing: accOklch.copyWith(l: 0.74, c: 0.16).toColor(),
      shape: ColorTheoryEngine.shiftHue(theme.accentColor, 40),
      frame: ColorTheoryEngine.shiftHue(theme.primaryColor, 35),
      container: ColorTheoryEngine.shiftHue(theme.primaryColor, -20),
      media: ColorTheoryEngine.shiftHue(theme.canvasAccentColor, 25),
      inter: ColorTheoryEngine.shiftHue(theme.canvasAccentColor, 60),
    );
  }
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

  factory CanvasColors.fromTheme(AppTheme theme) {
    return CanvasColors(
      selectionBorder: theme.primaryColor,
      selectionFill: theme.primaryColor.withValues(alpha: UiAlpha.tint),
      containerBorder: theme.canvasAccentColor,
      frameBorder: theme.accentColor,
      nodeHover: theme.primaryColor.withValues(alpha: UiAlpha.subtle),
      portIndicator: theme.primaryColor,
      portIndicatorActive: theme.accentColor,
      connectionLine: theme.textColor.withValues(alpha: UiAlpha.muted),
      connectionLineActive: theme.primaryColor,
      miniMapLens: theme.primaryColor.withValues(alpha: UiAlpha.medium),
      miniMapLensBorder: theme.primaryColor,
    );
  }
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

  factory SemanticColors.fromTheme(AppTheme theme) {
    return SemanticColors(
      success: theme.canvasAccentColor,
      warning: ColorTheoryEngine.shiftHue(theme.accentColor, 40),
      danger: ColorTheoryEngine.shiftHue(theme.accentColor, -30),
      info: theme.primaryColor,
    );
  }
}

/// Surfaces, card elevations, and border framing colors derived from the theme.
@immutable
class SurfaceColors {
  final Color panelBackground;
  final Color cardBackground;
  final Color dialogBackground;
  final Color borderSubtle;
  final Color borderStrong;

  const SurfaceColors({
    required this.panelBackground,
    required this.cardBackground,
    required this.dialogBackground,
    required this.borderSubtle,
    required this.borderStrong,
  });

  factory SurfaceColors.fromTheme(AppTheme theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SurfaceColors(
      panelBackground: isDark ? const Color(0xFF16181E) : const Color(0xFFFFFFFF),
      cardBackground: isDark ? const Color(0xFF1A1D24) : const Color(0xFFF8FAFC),
      dialogBackground: isDark ? const Color(0xFF12141A) : const Color(0xFFFFFFFF),
      borderSubtle: theme.dividerColor.withValues(alpha: isDark ? UiAlpha.medium : UiAlpha.borderSubtle),
      borderStrong: Colors.white.withValues(alpha: isDark ? UiAlpha.borderSubtle : UiAlpha.wash),
    );
  }
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
  final AppTheme? theme;

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

  /// Factory constructing the derived palette directly from an [AppTheme].
  factory CentrodeDerivedPalette.fromTheme(AppTheme theme) {
    final swatches = ColorTheoryEngine.deriveThemePalette(
      primary: theme.primaryColor,
      accent: theme.accentColor,
      canvasAccent: theme.canvasAccentColor,
    );

    final tagColors = [
      theme.primaryColor,
      theme.accentColor,
      theme.canvasAccentColor,
      ColorTheoryEngine.shiftHue(theme.primaryColor, 120),
      ColorTheoryEngine.shiftHue(theme.accentColor, 180),
    ];

    return CentrodeDerivedPalette._(
      theme: theme,
      alpha: const AlphaSettings(),
      swatches: swatches,
      tagColors: tagColors,
      nodeTints: NodeTintColors.fromTheme(theme),
      canvas: CanvasColors.fromTheme(theme),
      semantic: SemanticColors.fromTheme(theme),
      surface: SurfaceColors.fromTheme(theme),
      primaryAnalogous: ColorTheoryEngine.generateAnalogous(theme.primaryColor),
      primaryComplementary: ColorTheoryEngine.generateComplementary(theme.primaryColor),
      primaryTriadic: ColorTheoryEngine.generateTriadic(theme.primaryColor),
      primaryMonochromatic: ColorTheoryEngine.generateMonochromatic(theme.primaryColor),
    );
  }

  /// Factory constructing the derived palette from raw anchor colors.
  factory CentrodeDerivedPalette.fromColors({
    required Color primary,
    required Color accent,
    required Color canvasAccent,
    Brightness brightness = Brightness.dark,
  }) {
    final swatches = ColorTheoryEngine.deriveThemePalette(
      primary: primary,
      accent: accent,
      canvasAccent: canvasAccent,
    );

    final tagColors = [
      primary,
      accent,
      canvasAccent,
      ColorTheoryEngine.shiftHue(primary, 120),
      ColorTheoryEngine.shiftHue(accent, 180),
    ];

    final dummyTheme = AppTheme(
      primaryColor: primary,
      secondaryColor: primary,
      accentColor: accent,
      canvasAccentColor: canvasAccent,
      scaffoldBackgroundColor: const Color(0xFF101216),
      cardColor: const Color(0xFF1A1D24),
      dividerColor: const Color(0xFF334155),
      textColor: const Color(0xFFF8FAFC),
      fontFamily: 'Inter',
      bodyFontSize: 14.0,
      bodyFontWeight: FontWeight.w400,
      bodyTextColor: const Color(0xFFF8FAFC),
      borderRadius: 8.0,
      appBarBackgroundColor: const Color(0xFF101216),
      appBarForegroundColor: const Color(0xFFF8FAFC),
      appBarElevation: 0.0,
      appBarTitleFontSize: 16.0,
      appBarTitleFontWeight: FontWeight.w600,
      useMaterial3: true,
      brightness: brightness,
    );

    return CentrodeDerivedPalette._(
      alpha: const AlphaSettings(),
      swatches: swatches,
      tagColors: tagColors,
      nodeTints: NodeTintColors.fromTheme(dummyTheme),
      canvas: CanvasColors.fromTheme(dummyTheme),
      semantic: SemanticColors.fromTheme(dummyTheme),
      surface: SurfaceColors.fromTheme(dummyTheme),
      primaryAnalogous: ColorTheoryEngine.generateAnalogous(primary),
      primaryComplementary: ColorTheoryEngine.generateComplementary(primary),
      primaryTriadic: ColorTheoryEngine.generateTriadic(primary),
      primaryMonochromatic: ColorTheoryEngine.generateMonochromatic(primary),
    );
  }

  // ---------------------------------------------------------------------------
  // Color & Alpha Helpers
  // ---------------------------------------------------------------------------

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

  /// Global current derived palette from [AppThemeManager].
  static CentrodeDerivedPalette get current =>
      CentrodeDerivedPalette.fromTheme(AppThemeManager.instance.currentTheme);

  /// Convenience accessor to obtain the derived palette from context (or fallback to AppThemeManager).
  static CentrodeDerivedPalette of(BuildContext context) {
    final materialTheme = Theme.of(context);
    return CentrodeDerivedPalette.fromColors(
      primary: materialTheme.colorScheme.primary,
      accent: materialTheme.colorScheme.secondary,
      canvasAccent: materialTheme.colorScheme.tertiary,
      brightness: materialTheme.brightness,
    );
  }
}
