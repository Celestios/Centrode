import 'package:flutter/material.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class RecentMapTile extends StatelessWidget {
  final MapInfo map;
  final VoidCallback onTap;

  const RecentMapTile({
    super.key,
    required this.map,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: HoverScaleButton(
        onTap: onTap,
        hoverScale: 1.02,
        pressScale: 0.98,
        borderRadius: BorderRadius.circular(6),
        builder: (context, isHovered, isPressed) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: isHovered
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 0.8,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 0.8,
                    ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isHovered
                        ? primaryColor.withValues(alpha: 0.18)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    size: 12,
                    color: isHovered
                        ? primaryColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    map.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                      color: isHovered
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isHovered)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 10,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
