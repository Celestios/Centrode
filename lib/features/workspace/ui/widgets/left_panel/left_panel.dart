import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'quick_actions_section.dart';
import 'panel_footer_section.dart';

class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(UiRadius.panel),
        bottomRight: Radius.circular(UiRadius.panel),
      ),
      child: GlassPanel(
        width: WorkspaceTokens.leftPanelWidth,
        borderRadius: UiRadius.panel,
        enableBackdrop: false,
        color: isDark
            ? const Color(0xFF141418).withValues(alpha: 0.65)
            : const Color(0xFFE8E8E8).withValues(alpha: 0.85),
        child: Material(
          color: Colors.transparent,
          child: const Column(
            children: [
              Expanded(child: QuickActionsSection()),
              PanelFooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}
