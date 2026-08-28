import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'centrode_button.dart';

class HistoryBadgeButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final int count;
  final String tooltip;
  final VoidCallback? onTap;
  final Color textColor;

  const HistoryBadgeButton({
    super.key,
    required this.icon,
    required this.isEnabled,
    required this.count,
    required this.tooltip,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(UiRadius.card),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                            width: UiStrokeWidth.subtle,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
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
                              '$count',
                              key: ValueKey<int>(count),
                              style: TextStyle(
                                fontSize: UiFont.micro,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
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
