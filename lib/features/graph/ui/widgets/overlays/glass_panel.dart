import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic overlay panel that standardizes visual styling,
/// backdrop blur, clipping, and optional animated layouts.
class GlassPanel extends StatelessWidget {
  /// The widget content inside the panel.
  final Widget child;

  /// The strength of the backdrop blur filter.
  final double blur;

  /// The fallback opacity (alpha) of the default card background.
  final double alpha;

  /// The fallback border radius if the theme's cardTheme shape is not a [RoundedRectangleBorder].
  final double fallbackBorderRadius;

  /// The border radius to apply. If null, it is resolved from the theme's cardTheme.
  final BorderRadius? borderRadius;

  /// Custom decoration for the container. If provided, [backgroundColor], [border], and [boxShadow] are ignored.
  final Decoration? decoration;

  /// Custom background color of the panel. Defaults to `theme.cardColor.withValues(alpha: alpha)`.
  final Color? backgroundColor;

  /// Custom border for the panel. Defaults to `Border.all(color: theme.dividerColor.withValues(alpha: 0.3))`.
  final Border? border;

  /// List of box shadows for the panel.
  final List<BoxShadow>? boxShadow;

  /// Internal padding for the panel. If interactive, padding is placed inside the [InkWell] so the ripple covers it.
  final EdgeInsetsGeometry? padding;

  /// External margin around the panel.
  final EdgeInsetsGeometry? margin;

  /// Width of the panel.
  final double? width;

  /// Height of the panel.
  final double? height;

  /// If provided, the layout and styling changes will animate using an [AnimatedContainer].
  final Duration? duration;

  /// The animation curve to use when [duration] is provided.
  final Curve curve;

  /// Callback when the panel is tapped. If provided, renders an [InkWell] splash.
  final VoidCallback? onTap;

  /// Callback when the panel is long pressed. If provided, renders an [InkWell] splash.
  final VoidCallback? onLongPress;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.alpha = 0.85,
    this.fallbackBorderRadius = 16.0,
    this.borderRadius,
    this.decoration,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.duration,
    this.curve = Curves.easeInOut,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Resolve the border radius from theme or fallback
    final resolvedBorderRadius = borderRadius ??
        (theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(
                Directionality.maybeOf(context) ?? TextDirection.ltr)
            : BorderRadius.circular(fallbackBorderRadius));

    // Construct the box decoration
    final finalDecoration = decoration ??
        BoxDecoration(
          color: backgroundColor ?? theme.cardColor.withValues(alpha: alpha),
          borderRadius: resolvedBorderRadius,
          border: border ??
              Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: 1.0,
              ),
          boxShadow: boxShadow,
        );

    // Prepare interactive content overlay
    Widget content;
    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: resolvedBorderRadius,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      );
    } else {
      content = padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child;
    }

    // Build the container (animated or static)
    Widget container;
    if (duration != null) {
      container = AnimatedContainer(
        duration: duration!,
        curve: curve,
        width: width,
        height: height,
        margin: margin,
        decoration: finalDecoration,
        child: content,
      );
    } else {
      container = Container(
        width: width,
        height: height,
        margin: margin,
        decoration: finalDecoration,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}
