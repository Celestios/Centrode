import 'package:flutter/material.dart';

/// Configurable visual styling and theming for [UnravelSlider].
@immutable
class UnravelSliderThemeData {
  final Color? accentColor;
  final Color? trackBackgroundColor;
  final Color? trackBorderColor;
  final Color? handleBorderColor;
  final Color? handleShadowColor;
  final Color? textColor;
  final double cellWidth;
  final double cellHeight;
  final double iconSize;
  final double labelFontSize;
  final BorderRadius trackBorderRadius;
  final BorderRadius handleBorderRadius;

  const UnravelSliderThemeData({
    this.accentColor,
    this.trackBackgroundColor,
    this.trackBorderColor,
    this.handleBorderColor,
    this.handleShadowColor,
    this.textColor,
    this.cellWidth = 82.8,
    this.cellHeight = 55.2,
    this.iconSize = 25.3,
    this.labelFontSize = 12.6,
    this.trackBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.handleBorderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  /// Resolves effective theme properties using context's [ColorScheme] as defaults.
  UnravelSliderThemeData resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeText = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return UnravelSliderThemeData(
      accentColor: accentColor ?? scheme.primary,
      trackBackgroundColor: trackBackgroundColor ?? Colors.black.withValues(alpha: 0.3),
      trackBorderColor: trackBorderColor ?? Colors.white.withValues(alpha: 0.07),
      handleBorderColor: handleBorderColor ?? (accentColor ?? scheme.primary).withValues(alpha: 0.75),
      handleShadowColor: handleShadowColor ?? (accentColor ?? scheme.primary).withValues(alpha: 0.22),
      textColor: textColor ?? themeText,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      iconSize: iconSize,
      labelFontSize: labelFontSize,
      trackBorderRadius: trackBorderRadius,
      handleBorderRadius: handleBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnravelSliderThemeData &&
        other.accentColor == accentColor &&
        other.trackBackgroundColor == trackBackgroundColor &&
        other.trackBorderColor == trackBorderColor &&
        other.handleBorderColor == handleBorderColor &&
        other.handleShadowColor == handleShadowColor &&
        other.textColor == textColor &&
        other.cellWidth == cellWidth &&
        other.cellHeight == cellHeight &&
        other.iconSize == iconSize &&
        other.labelFontSize == labelFontSize &&
        other.trackBorderRadius == trackBorderRadius &&
        other.handleBorderRadius == handleBorderRadius;
  }

  @override
  int get hashCode => Object.hash(
        accentColor,
        trackBackgroundColor,
        trackBorderColor,
        handleBorderColor,
        handleShadowColor,
        textColor,
        cellWidth,
        cellHeight,
        iconSize,
        labelFontSize,
        trackBorderRadius,
        handleBorderRadius,
      );
}
