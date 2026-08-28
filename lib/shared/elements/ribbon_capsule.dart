import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

import 'glass_divider.dart';

class RibbonCapsule extends StatelessWidget {
  final Widget child;
  final String? label;

  const RibbonCapsule({
    super.key,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 3, right: 3),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: UiFont.micro,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
            GlassDivider(
              orientation: Axis.vertical,
              height: 18,
              useGradient: false,
              alpha: 0.15,
              margin: const EdgeInsets.only(right: 4),
            ),
          ],
          child,
        ],
      ),
    );
  }
}
