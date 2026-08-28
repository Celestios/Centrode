import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'centrode_button.dart';

class CentrodeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final double? buttonSize;
  final Color? iconColor;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final bool enableHover;
  final double hoverScale;
  final double pressScale;
  final bool compact;

  const CentrodeIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = UiIconSize.header,
    this.buttonSize,
    this.iconColor,
    this.hoverColor,
    this.borderRadius,
    this.enableHover = true,
    this.hoverScale = UiMotion.hoverScale,
    this.pressScale = UiMotion.pressScale,
    this.compact = false,
  });

  static const defaultIconSize = UiIconSize.header;
  static const defaultBorderRadius = BorderRadius.all(Radius.circular(UiRadius.control));

  @override
  Widget build(BuildContext context) {
    final effectiveColor = hoverColor ?? Theme.of(context).primaryColor;
    final effectiveBorderRadius = borderRadius ?? defaultBorderRadius;
    final effectiveIconColor = iconColor ??
        Theme.of(context).iconTheme.color?.withValues(alpha: 0.75);

    if (enableHover) {
      return CentrodeButton(
        onTap: onPressed,
        hoverScale: hoverScale,
        pressScale: pressScale,
        borderRadius: effectiveBorderRadius,
        tooltip: tooltip,
        builder: (context, isHovered, isPressed) {
          return _buildContent(
            context,
            isHovered: isHovered,
            effectiveColor: effectiveColor,
            effectiveBorderRadius: effectiveBorderRadius,
            effectiveIconColor: effectiveIconColor,
          );
        },
      );
    }

    return _buildPlainIcon(context);
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isHovered,
    required Color effectiveColor,
    required BorderRadius effectiveBorderRadius,
    required Color? effectiveIconColor,
  }) {
    return AnimatedContainer(
      duration: UiMotion.fast,
      width: buttonSize,
      height: buttonSize,
      padding: compact ? EdgeInsets.zero : null,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        gradient: isHovered
            ? LinearGradient(
                colors: [
                  effectiveColor.withValues(alpha: 0.18),
                  effectiveColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isHovered
            ? Border.all(
                color: effectiveColor.withValues(alpha: 0.3),
                width: UiStrokeWidth.standard,
              )
            : Border.all(color: Colors.transparent),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Icon(
          icon,
          color: isHovered ? effectiveColor : effectiveIconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildPlainIcon(BuildContext context) {
    final effectiveIconColor = iconColor ??
        Theme.of(context).iconTheme.color?.withValues(alpha: 0.75);

    Widget result = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius ?? defaultBorderRadius,
        onTap: onPressed,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }

    return result;
  }
}
