import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

class AnalyticsBox extends StatelessWidget {
  const AnalyticsBox({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: GlassPanel(
        height: 140,
        borderRadius: 12.0,
        enableBackdrop: false,
        color: palette.surface.subtleBackground,
        border: Border.all(
          color: palette.surface.controlBorder,
          width: UiStrokeWidth.subtle,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
