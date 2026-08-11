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
      borderRadius: BorderRadius.circular(6),
      enableHover: isEnabled,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 18,
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
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: count > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                            width: 0.8,
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
                            duration: const Duration(milliseconds: 200),
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
                                fontSize: 8,
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
