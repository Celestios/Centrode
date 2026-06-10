import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/viewport_state.dart';
import '../../../../presentation/graph_presentation_notifier.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'mini_map_painter.dart';

// -----------------------------------------------------------------------------
// BOTTOM RIGHT: Mini-Map Viewport Navigator (Custom Painted)
// -----------------------------------------------------------------------------
class ViewportMiniMapWidget extends StatelessWidget {
  const ViewportMiniMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphPresentationNotifier>().controller;
    final viewportController = context.watch<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final combined = Listenable.merge([
      viewportController.viewportStateNotifier,
      viewportController.elasticMargins,
    ]);

    return GlassPanel(
      borderRadius: 10,
      width: 200,
      height: 200,
      child: ListenableBuilder(
        listenable: combined,
        builder: (context, _) {
          final gridState = viewportController.viewportStateNotifier.value;
          final margins = viewportController.elasticMargins.value;

          return CustomPaint(
            painter: MiniMapPainter(
              nodes: dataController.nodeLookup.values.toList(),
              relations: dataController.relations.toList(),
              viewportSize: gridState.viewportSize,
              margins: margins,
              visibleRect: gridState.visibleRect,
              primaryColor: primaryColor,
            ),
          );
        },
      ),
    );
  }
}
