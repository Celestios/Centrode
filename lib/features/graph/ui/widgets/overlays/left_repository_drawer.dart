import 'package:flutter/material.dart';
import '../../../models/left_panel_type.dart';
import 'package:centrode/shared/elements/centrode_icon_tile.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

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
    return GlassPanel(
      padding: const EdgeInsets.all(3.0),
      borderRadius: 16.0,
      blur: 8.0,
      color: theme.cardColor.withValues(alpha: 0.90),
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
        width: 1.0,
      ),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CentrodeIconTile(
            icon: activePanel == LeftPanelType.tags
                ? Icons.arrow_back_rounded
                : Icons.local_offer_outlined,
            animateIcon: true,
            tileBorderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: () {
              onPanelChanged(
                activePanel == LeftPanelType.tags
                    ? LeftPanelType.none
                    : LeftPanelType.tags,
              );
            },
          ),
          const SizedBox(height: 1),
          CentrodeIconTile(
            icon: activePanel == LeftPanelType.templates
                ? Icons.arrow_back_rounded
                : Icons.layers_outlined,
            animateIcon: true,
            tileBorderRadius: const BorderRadius.all(Radius.circular(12)),
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
