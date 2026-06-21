import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import '../../../../presentation/graph_presentation_notifier.dart';

// -----------------------------------------------------------------------------
// BOTTOM CENTER: Graph Metrics & Async Progress Loader
// -----------------------------------------------------------------------------
class StatusMetricsWidget extends StatelessWidget {
  const StatusMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphPresentationNotifier>().controller;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    return GlassPanel(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dataController.isLoading) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'Nodes: ${dataController.nodeLookup.length}  |  Relations: ${dataController.relationLookup.length}',
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
