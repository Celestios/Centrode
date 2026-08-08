import 'package:flutter/material.dart';
import '../../../models/left_panel_type.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class LeftRepositoryDrawer extends StatelessWidget {
  final LeftPanelType activePanel;
  final void Function(LeftPanelType) onPanelChanged;

  const LeftRepositoryDrawer({
    super.key,
    required this.activePanel,
    required this.onPanelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor.withValues(alpha: 0.9);

    return GlassPanel(
      borderRadius: 16.0,
      blur: 12.0,
      color: cardColor,
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(3, 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassIconTile(
            icon: activePanel == LeftPanelType.tags
                ? Icons.arrow_back_rounded
                : Icons.local_offer_outlined,
            animateIcon: true,
            tileBorderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              onPanelChanged(
                activePanel == LeftPanelType.tags
                    ? LeftPanelType.none
                    : LeftPanelType.tags,
              );
            },
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.3),
            indent: 8,
            endIndent: 8,
          ),
          _GlassIconTile(
            icon: activePanel == LeftPanelType.templates
                ? Icons.arrow_back_rounded
                : Icons.layers_outlined,
            animateIcon: true,
            tileBorderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: () {
              onPanelChanged(
                activePanel == LeftPanelType.templates
                    ? LeftPanelType.none
                    : LeftPanelType.templates,
              );
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Glass icon tile
// -----------------------------------------------------------------------------

class _GlassIconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool animateIcon;
  final BorderRadius tileBorderRadius;

  const _GlassIconTile({
    required this.icon,
    required this.onTap,
    this.animateIcon = false,
    this.tileBorderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final iconSize = IconTheme.of(context).size ?? 24.0;

    return HoverScaleButton(
      onTap: onTap,
      hoverScale: 1.08,
      pressScale: 0.94,
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
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: iconWidget,
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
                    width: 1.0,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Center(child: iconWidget),
        );
      },
    );
  }
}
