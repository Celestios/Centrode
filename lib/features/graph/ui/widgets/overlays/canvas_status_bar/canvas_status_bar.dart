import 'package:flutter/material.dart';
import 'graph_manual_widget.dart';
import 'status_metrics_widget.dart';
import 'zoom_slider_widget.dart';
import 'viewport_mini_map_widget.dart';

class CanvasStatusBar extends StatelessWidget {
  const CanvasStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Bottom Left: Graph Manual / Conventions Legend
        const GraphManualWidget(),

        // Bottom Center: Graph Metrics & Sync Info
        const StatusMetricsWidget(),

        // Bottom Right: Zoom & Mini-Map group
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            ZoomSliderWidget(),
            SizedBox(width: 10),
            ViewportMiniMapWidget(),
          ],
        ),
      ],
    );
  }
}
