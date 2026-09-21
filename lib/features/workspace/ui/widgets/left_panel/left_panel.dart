import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';
import 'quick_actions_section.dart';
import 'panel_footer_section.dart';

class LeftPanel extends StatelessWidget {
  final WorkspaceHubController controller;

  const LeftPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final leftPanelColor = palette.surface.panelBackground;

    return GlassPanel(
      width: WorkspaceTokens.leftPanelWidth,
      customBorderRadius: const BorderRadius.only(
        topRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
        bottomRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
      ),
      enableBackdrop: false,
      color: leftPanelColor,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(child: QuickActionsSection(controller: controller)),
            const PanelFooterSection(),
          ],
        ),
      ),
    );
  }
}
