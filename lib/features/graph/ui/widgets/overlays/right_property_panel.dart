import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';

class RightPropertyPanel extends StatefulWidget {
  const RightPropertyPanel({super.key});

  @override
  State<RightPropertyPanel> createState() => _RightPropertyPanelState();
}

class _RightPropertyPanelState extends State<RightPropertyPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final renderState = context.watch<NodeRenderState>();
    final selectedEntities = renderState.selectedEntities;
    final isSelected = selectedEntities.isNotEmpty;

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: isSelected ? 220 : 0,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: borderRadiusVal,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(-3, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'INSPECTOR (${selectedEntities.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

                  // Placeholder Empty State
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: textColor.withValues(alpha: 0.3),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No properties available',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
