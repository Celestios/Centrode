import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:flutter/material.dart';
import 'showcase_painters.dart';

class InspectorShowcaseCardShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const InspectorShowcaseCardShell({
    super.key,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface.controlBackground,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(
          color: palette.surface.controlBorder,
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ShowcaseGridPainter(
              accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
