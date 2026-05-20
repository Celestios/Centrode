import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/viewport_state.dart';
import '../../../../store/graph_data_controller.dart';
import '../glass_panel.dart';
import 'mini_map_painter.dart';

// -----------------------------------------------------------------------------
// BOTTOM RIGHT: Mini-Map Viewport Navigator (Custom Painted)
// -----------------------------------------------------------------------------
class ViewportMiniMapWidget extends StatelessWidget {
  const ViewportMiniMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final viewportController = context.watch<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassPanel(
      fallbackBorderRadius: 10,
      width: 100,
      height: 70,
      child: ValueListenableBuilder<ViewportStateGrid>(
        valueListenable: viewportController.viewportStateNotifier,
        builder: (context, gridState, _) {
          return CustomPaint(
            painter: MiniMapPainter(
              nodes: dataController.nodeLookup.values.toList(),
              canvasBounds: dataController.canvasBounds.value,
              visibleRect: gridState.visibleRect,
              primaryColor: primaryColor,
            ),
          );
        },
      ),
    );
  }
}
