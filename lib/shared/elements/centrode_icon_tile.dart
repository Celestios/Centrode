import 'package:flutter/material.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';
import '../theme/design_tokens.dart';

class CentrodeIconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool animateIcon;
  final BorderRadius tileBorderRadius;

  const CentrodeIconTile({
    super.key,
    required this.icon,
    required this.onTap,
    this.animateIcon = false,
    this.tileBorderRadius = BorderRadius.zero,
  });

  static const defaultBorderRadius = BorderRadius.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final iconSize = IconTheme.of(context).size ?? 24.0;

    return HoverScaleButton(
      onTap: onTap,
      hoverScale: UiMotion.hoverScale,
      pressScale: UiMotion.pressScale,
      borderRadius: tileBorderRadius,
      builder: (context, isHovered, isPressed) {
        final iconColor = isHovered
            ? primaryColor
            : primaryColor.withValues(alpha: 0.7);

        Widget iconWidget = Icon(
          icon,
          key: ValueKey(icon),
          color: iconColor,
          size: iconSize,
        );

        if (animateIcon) {
          iconWidget = AnimatedSwitcher(
            duration: UiMotion.standard,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: iconWidget,
          );
        }

        return SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: UiMotion.fast,
                width: 40,
                height: UiControlSize.tile,
                decoration: BoxDecoration(
                  borderRadius: tileBorderRadius,
                  gradient: isHovered
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.18),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: isHovered
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: UiStrokeWidth.standard,
                        )
                      : null,
                ),
              ),
              iconWidget,
            ],
          ),
        );
      },
    );
  }
}
