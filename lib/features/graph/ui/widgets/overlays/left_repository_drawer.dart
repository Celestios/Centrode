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
    return GlassPanel(
      padding: const EdgeInsets.all(3.0),
      borderRadius: 16.0,
      blur: 8.0,
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
