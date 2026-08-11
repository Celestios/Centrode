import 'package:flutter/material.dart';

import '../../presentation/widgets/hover_scale_button.dart';

class CentrodeButton extends StatelessWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool isHovered, bool isPressed)?
      builder;
  final VoidCallback? onTap;
  final bool enableHover;
  final double hoverScale;
  final double pressScale;
  final Duration duration;
  final BorderRadius? borderRadius;
  final String? tooltip;
  final bool isEnabled;
  final ValueChanged<bool>? onHoverChanged;

  const CentrodeButton({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.enableHover = true,
    this.hoverScale = 1.08,
    this.pressScale = 0.94,
    this.duration = const Duration(milliseconds: 100),
    this.borderRadius,
    this.tooltip,
    this.isEnabled = true,
    this.onHoverChanged,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  static const defaultHoverScale = 1.05;
  static const defaultPressScale = 0.95;
  static const defaultDuration = Duration(milliseconds: 100);
  static const defaultBorderRadius = BorderRadius.all(Radius.circular(10));

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? defaultBorderRadius;

    if (enableHover) {
      return HoverScaleButton(
        onTap: onTap,
        hoverScale: hoverScale,
        pressScale: pressScale,
        duration: duration,
        isEnabled: isEnabled,
        tooltip: tooltip,
        borderRadius: effectiveBorderRadius,
        onHoverChanged: onHoverChanged,
        builder: builder,
        child: child,
      );
    }

    final content =
        builder != null ? builder!(context, false, false) : child!;

    Widget result = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: effectiveBorderRadius,
        onTap: isEnabled ? onTap : null,
        child: content,
      ),
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }

    return result;
  }
}
