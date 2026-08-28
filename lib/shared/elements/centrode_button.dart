import 'package:flutter/material.dart';
import '../../presentation/widgets/hover_scale_button.dart';
import '../theme/design_tokens.dart';

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
    this.hoverScale = UiMotion.hoverScale,
    this.pressScale = UiMotion.pressScale,
    this.duration = UiMotion.fast,
    this.borderRadius,
    this.tooltip,
    this.isEnabled = true,
    this.onHoverChanged,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  static const defaultHoverScale = UiMotion.hoverScale;
  static const defaultPressScale = UiMotion.pressScale;
  static const defaultDuration = UiMotion.fast;
  static const defaultBorderRadius = BorderRadius.all(Radius.circular(UiRadius.card));

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
