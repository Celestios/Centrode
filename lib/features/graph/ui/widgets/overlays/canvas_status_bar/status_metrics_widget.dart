import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../../../store/graph_data_query_controller.dart';
import '../../../../store/graph_data_query.dart';

class StatusMetricsWidget extends StatelessWidget {
  const StatusMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final queryController = context.read<GraphDataQueryController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final preset = GlassPresets.toolbar(context);
    return GlassPanel(
      borderRadius: preset.borderRadius ?? 10,
      color: preset.color,
      shadow: preset.shadow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: StreamBuilder<GraphEntityUpdate>(
        stream: queryController.onEntityUpdate,
        builder: (context, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: queryController.isLoadingNotifier,
            builder: (context, isLoading, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: UiStrokeWidth.thick,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                  ],
                  Text(
                    'Nodes: ${queryController.nodeLookup.length}',
                    style: TextStyle(
                      fontSize: UiFont.compact,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const GlassDivider(
                    useGradient: true,
                    height: 14,
                    width: 1.2,
                  ),
                  Text(
                    'Relations: ${queryController.relationLookup.length}',
                    style: TextStyle(
                      fontSize: UiFont.compact,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
