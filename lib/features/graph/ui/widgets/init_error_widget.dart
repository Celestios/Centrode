import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:flutter/material.dart';

class InitErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onShowDetails;

  const InitErrorWidget({
    super.key,
    required this.error,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: GlassPanel(
          borderRadius: UiRadius.panel,
          blur: 16.0,
          padding: const EdgeInsets.all(UiSpacing.gutter),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.6),
            width: UiStrokeWidth.standard,
          ),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: UiSpacing.container),
                Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: UiFont.standard,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: UiSpacing.standard),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: UiFont.compact,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (onShowDetails != null) ...[
                  const SizedBox(height: UiSpacing.container),
                  Center(
                    child: GestureDetector(
                      onTap: onShowDetails,
                      child: Text(
                        'Show Details',
                        style: TextStyle(
                          fontSize: UiFont.compact,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
