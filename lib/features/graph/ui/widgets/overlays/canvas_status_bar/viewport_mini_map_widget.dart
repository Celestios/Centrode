import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/viewport_state.dart';
import '../../../../presentation/graph_presentation_notifier.dart';
import '../../../../presentation/node_render_state.dart';
import '../../../../presentation/view_state.dart';
import '../../../../models/models.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

class ViewportMiniMapWidget extends StatefulWidget {
  const ViewportMiniMapWidget({super.key});

  @override
  State<ViewportMiniMapWidget> createState() => _ViewportMiniMapWidgetState();
}

class _ViewportMiniMapWidgetState extends State<ViewportMiniMapWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _captureKey = GlobalKey();
  ui.Image? _snapshot;
  Ticker? _viewportTicker;
  double _viewportLeft = 0;
  double _viewportTop = 0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _viewportTicker = createTicker(_onViewportTick);
    _viewportTicker!.start();
    final notifier = context.read<GraphPresentationNotifier>();
    notifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _viewportTicker?.dispose();
    _snapshot?.dispose();
    try {
      context.read<GraphPresentationNotifier>().removeListener(_onDataChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onDataChanged() {
    _snapshot = null;
    _scheduleCapture();
  }

  void _scheduleCapture() {
    if (_capturing) return;
    _capturing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureSnapshot();
    });
  }

  void _onViewportTick(Duration elapsed) {
    final vc = context.read<ViewportController>();
    final gridState = vc.viewportStateNotifier.value;
    final margins = vc.elasticMargins.value;

    // Trigger re-capture when viewport transitions from zero to non-zero
    if (_snapshot == null && !_capturing && gridState.viewportSize != Size.zero) {
      final dataController = context.read<GraphPresentationNotifier>().controller;
      final nodes = dataController.nodeLookup.values.toList();
      if (nodes.isNotEmpty) {
        _scheduleCapture();
      }
    }

    final totalW = gridState.viewportSize.width + margins.left + margins.right;
    final totalH = gridState.viewportSize.height + margins.top + margins.bottom;
    if (totalW == 0 || totalH == 0) return;

    final newLeft = (gridState.visibleRect.left + margins.left) / totalW;
    final newTop = (gridState.visibleRect.top + margins.top) / totalH;
    final newWidth = gridState.visibleRect.width / totalW;
    final newHeight = gridState.visibleRect.height / totalH;

    if ((newLeft - _viewportLeft).abs() > 0.001 ||
        (newTop - _viewportTop).abs() > 0.001 ||
        (newWidth - _viewportWidth).abs() > 0.001 ||
        (newHeight - _viewportHeight).abs() > 0.001) {
      setState(() {
        _viewportLeft = newLeft;
        _viewportTop = newTop;
        _viewportWidth = newWidth;
        _viewportHeight = newHeight;
      });
    }
  }

  Future<void> _captureSnapshot() async {
    final boundary = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      _capturing = false;
      return;
    }

    final oldSnapshot = _snapshot;

    try {
      final image = await boundary.toImage(pixelRatio: 1.5);
      if (!mounted) {
        image.dispose();
        _capturing = false;
        return;
      }
      setState(() {
        _snapshot = image;
      });
      if (oldSnapshot != null && identical(oldSnapshot, _snapshot) == false) {
        oldSnapshot.dispose();
      }
    } catch (_) {}
    _capturing = false;
  }

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphPresentationNotifier>().controller;
    final viewportController = context.watch<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final nodes = dataController.nodeLookup.values.toList();
    final relations = dataController.relations.toList();
    final viewStates = context.read<NodeRenderState>().viewStates;
    final gridState = viewportController.viewportStateNotifier.value;
    final margins = viewportController.elasticMargins.value;

    if (_snapshot == null && !_capturing && nodes.isNotEmpty && gridState.viewportSize != Size.zero) {
      _scheduleCapture();
    }

    final viewportFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final viewportBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    return GlassPanel(
      borderRadius: 10,
      width: 200,
      height: 200,
      child: _snapshot != null
          ? CustomPaint(
              size: const Size(200, 200),
              painter: _SnapshotPainter(
                snapshot: _snapshot!,
                viewportLeft: _viewportLeft,
                viewportTop: _viewportTop,
                viewportWidth: _viewportWidth,
                viewportHeight: _viewportHeight,
                viewportFill: viewportFill,
                viewportBorder: viewportBorder,
              ),
            )
          : RepaintBoundary(
              key: _captureKey,
              child: _MiniMapContent(
                nodes: nodes,
                relations: relations,
                viewStates: viewStates,
                primaryColor: primaryColor,
                viewportSize: gridState.viewportSize,
                margins: margins,
              ),
            ),
    );
  }
}

class _MiniMapContent extends StatelessWidget {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final Map<String, NodeViewState> viewStates;
  final Color primaryColor;
  final Size viewportSize;
  final EdgeInsets margins;

  const _MiniMapContent({
    required this.nodes,
    required this.relations,
    required this.viewStates,
    required this.primaryColor,
    required this.viewportSize,
    required this.margins,
  });

  @override
  Widget build(BuildContext context) {
    final double totalW = viewportSize.width + margins.left + margins.right;
    final double totalH = viewportSize.height + margins.top + margins.bottom;
    final scale = totalW > totalH ? 200 / totalW : 200 / totalH;
    final offsetX = (200 - totalW * scale) / 2;
    final offsetY = (200 - totalH * scale) / 2;

    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _MiniMapContentPainter(
          nodes: nodes,
          relations: relations,
          viewStates: viewStates,
          primaryColor: primaryColor,
          totalW: totalW,
          totalH: totalH,
          margins: margins,
          scale: scale,
          offsetX: offsetX,
          offsetY: offsetY,
        ),
      ),
    );
  }
}

class _MiniMapContentPainter extends CustomPainter {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final Map<String, NodeViewState> viewStates;
  final Color primaryColor;
  final double totalW;
  final double totalH;
  final EdgeInsets margins;
  final double scale;
  final double offsetX;
  final double offsetY;

  _MiniMapContentPainter({
    required this.nodes,
    required this.relations,
    required this.viewStates,
    required this.primaryColor,
    required this.totalW,
    required this.totalH,
    required this.margins,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  Offset _toMini(Offset pos) {
    return Offset(
      (pos.dx + margins.left) * scale + offsetX,
      (pos.dy + margins.top) * scale + offsetY,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (var n in nodes) n.id: n};

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (final rel in relations) {
      final from = nodeMap[rel.fromNodeId];
      final to = nodeMap[rel.toNodeId];
      if (from == null || to == null) continue;

      final fromCenter = from.position + Offset(from.size.width / 2, from.size.height / 2);
      final toCenter = to.position + Offset(to.size.width / 2, to.size.height / 2);

      canvas.drawLine(_toMini(fromCenter), _toMini(toCenter), linePaint);
    }

    for (final node in nodes) {
      final miniPos = _toMini(node.position);
      final w = node.size.width * scale;
      final h = node.size.height * scale;

      if (miniPos.dx + w < 0 || miniPos.dx > size.width ||
          miniPos.dy + h < 0 || miniPos.dy > size.height) {
        continue;
      }

      final bgColor = Color(
        node.resolvedStyle?.bgColor ?? node.style?.bgColor ?? primaryColor.toARGB32(),
      );
      final borderRadius = node.resolvedStyle?.borderRadius ?? 4.0;

      final fillPaint = Paint()..color = bgColor;
      final borderPaint = Paint()
        ..color = (node.resolvedStyle?.strokeColor != null)
            ? Color(node.resolvedStyle!.strokeColor)
            : primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(miniPos.dx, miniPos.dy, w, h),
        Radius.circular(borderRadius * scale),
      );

      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapContentPainter oldDelegate) => false;
}

class _SnapshotPainter extends CustomPainter {
  final ui.Image snapshot;
  final double viewportLeft;
  final double viewportTop;
  final double viewportWidth;
  final double viewportHeight;
  final Paint viewportFill;
  final Paint viewportBorder;

  _SnapshotPainter({
    required this.snapshot,
    required this.viewportLeft,
    required this.viewportTop,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.viewportFill,
    required this.viewportBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: snapshot,
      fit: BoxFit.fill,
    );

    final vpRect = Rect.fromLTWH(
      viewportLeft * size.width,
      viewportTop * size.height,
      viewportWidth * size.width,
      viewportHeight * size.height,
    ).intersect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(vpRect, viewportFill);
    canvas.drawRect(vpRect, viewportBorder);
  }

  @override
  bool shouldRepaint(covariant _SnapshotPainter oldDelegate) {
    return oldDelegate.viewportLeft != viewportLeft ||
        oldDelegate.viewportTop != viewportTop ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.viewportHeight != viewportHeight;
  }
}
