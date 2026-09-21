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
    if (label == null) {
      return child;
    }
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
        child,
      ],
    );
  }
}
