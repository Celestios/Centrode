import 'package:flutter/material.dart';
import '../../../models/left_panel_type.dart';
import 'glass_panel.dart'; // adjust path as needed

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
    final dividerColor = theme.dividerColor.withValues(alpha: 0.3);

    // The whole button group sits inside a single GlassPanel
    return Center(
      child: GlassPanel(
        blur: 12.0, // matches sidebar’s glass
        alpha: 0.85,
        fallbackBorderRadius: 16.0,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        // No internal padding – the child handles its own spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassIconTile(
              icon: activePanel == LeftPanelType.tags ? Icons.arrow_back_rounded : Icons.local_offer,
              onTap: () {
                if (activePanel == LeftPanelType.tags) {
                  onPanelChanged(LeftPanelType.none);
                } else {
                  onPanelChanged(LeftPanelType.tags);
                }
              },
              animateIcon: true,
            ),
            Divider(height: 1, color: dividerColor),
            _GlassIconTile(
              icon: activePanel == LeftPanelType.templates ? Icons.arrow_back_rounded : Icons.copy_all_outlined,
              onTap: () {
                if (activePanel == LeftPanelType.templates) {
                  onPanelChanged(LeftPanelType.none);
                } else {
                  onPanelChanged(LeftPanelType.templates);
                }
              },
              animateIcon: true,
            ),
            Divider(height: 1, color: dividerColor),
            _GlassIconTile(
              icon: Icons.file_open_outlined,
              onTap: () => debugPrint('Open tapped'),
            ),
            Divider(height: 1, color: dividerColor),
            _GlassIconTile(
              icon: Icons.save_alt_outlined,
              onTap: () => debugPrint('Save tapped'),
            ),
            Divider(height: 1, color: dividerColor),
            _GlassIconTile(
              icon: Icons.settings_outlined,
              onTap: () => debugPrint('Settings tapped'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable icon row that sits inside the glass group.
/// It uses [InkWell] for the ripple and respects the theme.
class _GlassIconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool animateIcon;

  const _GlassIconTile({
    required this.icon,
    this.onTap,
    this.animateIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    final iconSize = IconTheme.of(context).size ?? 24.0;

    Widget iconWidget = Icon(icon, key: ValueKey(icon), color: iconColor, size: iconSize);

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

    // Material + InkWell gives proper touch feedback inside the GlassPanel
    return Material(
      color: Colors.transparent, // transparent so GlassPanel background shows
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: iconWidget,
        ),
      ),
    );
  }
}
