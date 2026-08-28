import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'graph_manual_widget.dart';
import 'status_metrics_widget.dart';
import 'zoom_slider_widget.dart';
import 'viewport_mini_map_widget.dart';
import 'status_bar_metrics.dart';

class CanvasStatusBar extends StatelessWidget {
  const CanvasStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = MediaQuery.sizeOf(context).height;

        // Guard against zero layout width
        if (maxWidth <= 0) return const SizedBox.shrink();

        final showMiniMap = CanvasStatusBarMetrics.shouldShowMiniMap(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        final showMetrics = CanvasStatusBarMetrics.shouldShowMetrics(maxWidth);
        final showZoom = CanvasStatusBarMetrics.shouldShowZoom();
        final showManual = CanvasStatusBarMetrics.shouldShowManual(maxWidth);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bottom Left: Graph Manual / Conventions Legend
            if (showManual) const GraphManualWidget(),

            // Bottom Center: Graph Metrics & Sync Info (Disabled on Android)
            if (showMetrics) const StatusMetricsWidget(),

            // Bottom Right: Zoom & Mini-Map group (Disabled on Android)
            if (showZoom)
              GlassGroup(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const ZoomSliderWidget(),
                    if (showMiniMap) ...[
                      const SizedBox(width: UiSpacing.standard),
                      const ViewportMiniMapWidget(),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
