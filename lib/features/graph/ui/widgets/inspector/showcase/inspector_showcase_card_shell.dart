import 'package:centrode/shared/theme/design_tokens.dart';
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
    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ShowcaseGridPainter(accentColor.withValues(alpha: 0.12)),
          ),
          child,
        ],
      ),
    );
  }
}
