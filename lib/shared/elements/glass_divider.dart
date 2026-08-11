import 'package:flutter/material.dart';

class GlassDivider extends StatelessWidget {
  final Axis orientation;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final double alpha;
  final bool useGradient;

  const GlassDivider({
    super.key,
    this.orientation = Axis.vertical,
    this.width,
    this.height,
    this.margin,
    this.alpha = 0.3,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVertical = orientation == Axis.vertical;

    final effectiveWidth = width ?? (isVertical ? 1.2 : null);
    final effectiveHeight = height ?? (isVertical ? 26.0 : 1.0);
    final effectiveMargin = margin ??
        (isVertical
            ? const EdgeInsets.symmetric(horizontal: 3)
            : const EdgeInsets.symmetric(vertical: 2));

    if (useGradient) {
      final gradientColors = [
        theme.dividerColor.withValues(alpha: 0.0),
        theme.dividerColor.withValues(alpha: 0.35),
        theme.dividerColor.withValues(alpha: 0.0),
      ];

      return Container(
        margin: effectiveMargin,
        width: effectiveWidth,
        height: effectiveHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
            end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          ),
        ),
      );
    }

    return Container(
      margin: effectiveMargin,
      width: effectiveWidth,
      height: effectiveHeight,
      color: theme.dividerColor.withValues(alpha: alpha),
    );
  }
}
