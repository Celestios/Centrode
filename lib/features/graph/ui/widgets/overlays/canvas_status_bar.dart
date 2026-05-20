import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/viewport_state.dart';
import '../../../store/graph_data_controller.dart';

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

// -----------------------------------------------------------------------------
// BOTTOM LEFT: Graph Manual Legend Dialog Trigger
// -----------------------------------------------------------------------------
class GraphManualWidget extends StatelessWidget {
  const GraphManualWidget({super.key});

  void _showManualDialog(BuildContext context, ThemeData theme, Color primaryColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: theme.cardColor.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  'MAP CONVENTIONS & MANUAL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Node Types', primaryColor),
                  _buildLegendRow(primaryColor, 'Info Node', 'Core informational units, general content.', textColor),
                  _buildLegendRow(Colors.greenAccent, 'Task Node', 'Actionable checklist nodes or tracking items.', textColor),
                  _buildLegendRow(Colors.yellowAccent, 'Inter Node', 'Intermediate linkage or transition entities.', textColor),
                  const SizedBox(height: 12),
                  _buildSectionHeader('Connection Lines', primaryColor),
                  _buildLegendRow(textColor.withValues(alpha: 0.7), 'Solid Line', 'Direct association, standard labeled relation.', textColor),
                  _buildLegendRow(textColor.withValues(alpha: 0.5), 'Dashed Line', 'Soft association or conditional dependency.', textColor),
                  const SizedBox(height: 12),
                  _buildSectionHeader('Canvas Interaction Controls', primaryColor),
                  Text(
                    '• Pan View: Hold Middle Click or Space + Drag.\n'
                    '• Zoom: Use Mouse Scroll Wheel.\n'
                    '• Double Tap Canvas: Create a new Node.\n'
                    '• Drag Selection: Hold shift and drag selection marquee.',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String name, String desc, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: theme.cardColor.withValues(alpha: 0.85),
          borderRadius: borderRadiusVal,
          child: InkWell(
            borderRadius: borderRadiusVal,
            onTap: () => _showManualDialog(context, theme, primaryColor, textColor),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: borderRadiusVal,
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, color: primaryColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Manual & Guide',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.7),
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

// -----------------------------------------------------------------------------
// BOTTOM CENTER: Graph Metrics & Async Progress Loader
// -----------------------------------------------------------------------------
class StatusMetricsWidget extends StatelessWidget {
  const StatusMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: borderRadiusVal,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
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
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BOTTOM RIGHT: Zoom slider & percentage indicator
// -----------------------------------------------------------------------------
class ZoomSliderWidget extends StatelessWidget {
  const ZoomSliderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewportController = context.watch<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: borderRadiusVal,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: ValueListenableBuilder<ViewportStateGrid>(
            valueListenable: viewportController.viewportStateNotifier,
            builder: (context, gridState, _) {
              final double scale = gridState.scale;
              final percent = (scale * 100).toInt();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_out, color: textColor.withValues(alpha: 0.7), size: 14),
                    onPressed: () => _updateZoom(viewportController, (scale - 0.1).clamp(0.2, 3.0)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 80,
                    height: 20,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.3),
                        thumbColor: primaryColor,
                      ),
                      child: Slider(
                        value: scale,
                        min: 0.2,
                        max: 3.0,
                        onChanged: (val) => _updateZoom(viewportController, val),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in, color: textColor.withValues(alpha: 0.7), size: 14),
                    onPressed: () => _updateZoom(viewportController, (scale + 0.1).clamp(0.2, 3.0)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _updateZoom(ViewportController controller, double newScale) {
    final currentMatrix = controller.transformController.value;
    final translation = currentMatrix.getTranslation();
    final newMatrix = Matrix4.identity()
      ..translate(translation.x, translation.y)
      ..scale(newScale);
    controller.transformController.value = newMatrix;
  }
}

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

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: borderRadiusVal,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
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
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final List<dynamic> nodes;
  final dynamic canvasBounds;
  final Rect visibleRect;
  final Color primaryColor;

  MiniMapPainter({
    required this.nodes,
    required this.canvasBounds,
    required this.visibleRect,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Resolve bounding box coordinates
    final double minX = canvasBounds.minX.toDouble();
    final double maxX = canvasBounds.maxX.toDouble();
    final double minY = canvasBounds.minY.toDouble();
    final double maxY = canvasBounds.maxY.toDouble();

    final double graphWidth = (maxX - minX).clamp(100.0, double.infinity);
    final double graphHeight = (maxY - minY).clamp(100.0, double.infinity);

    // Padding inside the mini-map viewport
    const double padding = 8.0;
    final double areaWidth = size.width - (padding * 2);
    final double areaHeight = size.height - (padding * 2);

    // 2. Scale factor calculation to fit graph bounds into mini-map size
    final double scaleX = areaWidth / graphWidth;
    final double scaleY = areaHeight / graphHeight;
    final double scale = math.min(scaleX, scaleY);

    // Translation offsets to center graph inside mini-map
    final double offsetX = padding + (areaWidth - graphWidth * scale) / 2 - minX * scale;
    final double offsetY = padding + (areaHeight - graphHeight * scale) / 2 - minY * scale;

    Offset canvasToMiniMap(Offset pos) {
      return Offset(
        pos.dx * scale + offsetX,
        pos.dy * scale + offsetY,
      );
    }

    // 3. Draw node dots
    final nodePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      final miniPos = canvasToMiniMap(node.position);
      // Guard bounds checking
      if (miniPos.dx >= 0 && miniPos.dx <= size.width && miniPos.dy >= 0 && miniPos.dy <= size.height) {
        canvas.drawCircle(miniPos, 1.8, nodePaint);
      }
    }

    // 4. Draw current viewport rectangle
    final topLeft = canvasToMiniMap(visibleRect.topLeft);
    final bottomRight = canvasToMiniMap(visibleRect.bottomRight);
    final viewportRect = Rect.fromPoints(topLeft, bottomRight).intersect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final viewportFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final viewportBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(viewportRect, viewportFill);
    canvas.drawRect(viewportRect, viewportBorder);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return oldDelegate.nodes.length != nodes.length ||
        oldDelegate.canvasBounds != canvasBounds ||
        oldDelegate.visibleRect != visibleRect ||
        oldDelegate.primaryColor != primaryColor;
  }
}
