import 'package:flutter/material.dart';
import 'graph_manual_widget.dart';
import 'status_metrics_widget.dart';
import 'zoom_slider_widget.dart';
import 'viewport_mini_map_widget.dart';

class CanvasStatusBar extends StatelessWidget {
  const CanvasStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // Guard against zero layout width
        if (maxWidth <= 0) return const SizedBox.shrink();

        final showMiniMap = maxWidth >= 700;
        final showMetrics = maxWidth >= 500;
        final showManual = maxWidth >= 300;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bottom Left: Graph Manual / Conventions Legend
            if (showManual) const GraphManualWidget() else const SizedBox.shrink(),

            // Bottom Center: Graph Metrics & Sync Info
            if (showMetrics) const StatusMetricsWidget() else const SizedBox.shrink(),

            // Bottom Right: Zoom & Mini-Map group
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ZoomSliderWidget(),
                if (showMiniMap) ...[
                  const SizedBox(width: 10),
                  const ViewportMiniMapWidget(),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
