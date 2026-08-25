import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class TabItem extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const TabItem({
    super.key,
    required this.name,
    required this.isActive,
    required this.canClose,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final activeColor = onSurface;
    final inactiveColor = onSurface.withValues(alpha: 0.6);

    return HoverScaleButton(
      onTap: onTap,
      hoverScale: 1.04,
      pressScale: 0.96,
      borderRadius: BorderRadius.circular(10),
      builder: (context, isHovered, isPressed) {
        final preset = GlassPresets.tab(context, isActive: isActive);
        return GlassPanel(
          borderRadius: preset.borderRadius ?? 10,
          color: isActive
              ? preset.color
              : (isHovered
                    ? theme.cardColor.withValues(alpha: 0.60)
                    : preset.color),
          shadow: preset.shadow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: isActive
                      ? activeColor
                      : (isHovered ? primaryColor : inactiveColor),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? activeColor
                        : (isHovered ? primaryColor : inactiveColor),
                  ),
                ),
                if (canClose) ...[
                  const SizedBox(width: 8),
                  CentrodeIconButton(
                    icon: Icons.close_rounded,
                    onPressed: onClose,
                    iconSize: 14,
                    buttonSize: 20,
                    iconColor: isActive
                        ? activeColor.withValues(alpha: 0.6)
                        : (isHovered
                              ? primaryColor.withValues(alpha: 0.6)
                              : inactiveColor.withValues(alpha: 0.6)),
                    enableHover: false,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
