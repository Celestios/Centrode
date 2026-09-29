import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'centrode_button.dart';

class CentrodeBadge extends StatelessWidget {
  final int count;
  final String? label;
  final Color? color;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const CentrodeBadge({
    super.key,
    this.count = 0,
    this.label,
    this.color,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.primary;

    final displayLabel = label ?? '$count';
    if (count <= 0 && label == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDark ? 0.85 : 0.90),
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.40),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 14,
        minHeight: 14,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: UiMotion.standard,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Text(
            displayLabel,
            key: ValueKey<String>(displayLabel),
            style: textStyle ??
                TextStyle(
                  fontSize: UiFont.micro,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
          ),
        ),
      ),
    );
  }
}

class CentrodeBadgeButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final int count;
  final String tooltip;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? badgeColor;

  const CentrodeBadgeButton({
    super.key,
    required this.icon,
    required this.isEnabled,
    required this.count,
    required this.tooltip,
    required this.onTap,
    required this.textColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return CentrodeButton(
      onTap: isEnabled ? onTap : null,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(UiRadius.control),
      enableHover: isEnabled,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: UiIconSize.standard,
              color: !isEnabled
                  ? textColor.withValues(alpha: 0.25)
                  : textColor.withValues(alpha: 0.85),
            ),
            if (count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: count > 0 ? 1.0 : 0.0,
                    duration: UiMotion.standard,
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: count > 0 ? 1.0 : 0.0,
                      duration: UiMotion.fast,
                      child: CentrodeBadge(
                        count: count,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef HistoryBadgeButton = CentrodeBadgeButton;
