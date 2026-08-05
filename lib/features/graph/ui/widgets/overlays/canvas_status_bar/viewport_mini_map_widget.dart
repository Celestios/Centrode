import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/viewport_state.dart';
import '../../../../presentation/node_render_state.dart';
import '../../../../models/models.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'mini_map_painter.dart';

class ViewportMiniMapWidget extends StatefulWidget {
  const ViewportMiniMapWidget({super.key});

  @override
  State<ViewportMiniMapWidget> createState() => _ViewportMiniMapWidgetState();
}

class _ViewportMiniMapWidgetState extends State<ViewportMiniMapWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _captureKey = GlobalKey();
  ui.Image? _snapshot;
  Ticker? _viewportTicker;
  double _viewportLeft = 0;
  double _viewportTop = 0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  bool _capturing = false;
  bool _listenerRegistered = false;

  NodeRenderState? _cachedRenderState;
  late final Paint _viewportFill = Paint()..style = PaintingStyle.fill;
  late final Paint _viewportBorder = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewportTicker = createTicker(_onViewportTick);
    _startTickerIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cachedRenderState = context.read<NodeRenderState>();
      _cachedRenderState!.addListener(_onGraphChanged);
      _listenerRegistered = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewportTicker?.dispose();
    _snapshot?.dispose();
    if (_listenerRegistered && _cachedRenderState != null) {
      _cachedRenderState!.removeListener(_onGraphChanged);
    }
    _cachedRenderState = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pauseTicker();
    } else if (state == AppLifecycleState.resumed) {
      _startTickerIfNeeded();
    }
  }

  void _startTickerIfNeeded() {
    if (_viewportTicker != null && !_viewportTicker!.isActive) {
      _viewportTicker!.start();
    }
  }

  void _pauseTicker() {
    if (_viewportTicker != null && _viewportTicker!.isActive) {
      _viewportTicker!.stop();
    }
  }

  void _onGraphChanged() {
    setState(() {
      _snapshot = null;
    });
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
    if (_snapshot == null &&
        !_capturing &&
        gridState.viewportSize != Size.zero) {
      final renderState = context.read<NodeRenderState>();
      if (renderState.nodeLookup.isNotEmpty) {
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
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _captureSnapshot();
      });
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

  void _handleMiniMapInteraction(
    Offset localPosition,
    ViewportController controller,
  ) {
    const Size miniMapSize = Size(200, 200);
    final clampedX = localPosition.dx.clamp(0.0, miniMapSize.width);
    final clampedY = localPosition.dy.clamp(0.0, miniMapSize.height);

    final gridState = controller.viewportStateNotifier.value;
    final margins = controller.elasticMargins.value;
    final viewportSize = gridState.viewportSize;

    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final double totalW = viewportSize.width + margins.left + margins.right;
    final double totalH = viewportSize.height + margins.top + margins.bottom;

    if (totalW <= 0 || totalH <= 0) return;

    final double scaleX = miniMapSize.width / totalW;
    final double scaleY = miniMapSize.height / totalH;

    final double canvasX = (clampedX / scaleX) - margins.left;
    final double canvasY = (clampedY / scaleY) - margins.top;

    controller.centerOnCanvasPoint(Offset(canvasX, canvasY));
  }

  @override
  Widget build(BuildContext context) {
    final renderState = context.read<NodeRenderState>();
    final viewportController = context.read<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final nodes = renderState.nodeLookup.values.toList();
    final relations = renderState.relations.toList();
    final gridState = viewportController.viewportStateNotifier.value;
    final margins = viewportController.elasticMargins.value;

    _viewportFill.color = primaryColor.withValues(alpha: 0.08);
    _viewportBorder.color = primaryColor.withValues(alpha: 0.5);

    return GlassPanel(
      borderRadius: 10,
      width: 200,
      height: 200,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleMiniMapInteraction(
            details.localPosition,
            viewportController,
          ),
          onPanUpdate: (details) => _handleMiniMapInteraction(
            details.localPosition,
            viewportController,
          ),
          onPanEnd: (_) => viewportController.recalculateElasticMargins(),
          onTapUp: (_) => viewportController.recalculateElasticMargins(),
          child: _snapshot != null
              ? CustomPaint(
                  size: const Size(200, 200),
                  painter: _SnapshotPainter(
                    snapshot: _snapshot!,
                    viewportLeft: _viewportLeft,
                    viewportTop: _viewportTop,
                    viewportWidth: _viewportWidth,
                    viewportHeight: _viewportHeight,
                    viewportFill: _viewportFill,
                    viewportBorder: _viewportBorder,
                  ),
                )
              : RepaintBoundary(
                  key: _captureKey,
                  child: _MiniMapContent(
                    nodes: nodes,
                    relations: relations,
                    primaryColor: primaryColor,
                    viewportSize: gridState.viewportSize,
                    margins: margins,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MiniMapContent extends StatelessWidget {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final Color primaryColor;
  final Size viewportSize;
  final EdgeInsets margins;

  const _MiniMapContent({
    required this.nodes,
    required this.relations,
    required this.primaryColor,
    required this.viewportSize,
    required this.margins,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: MiniMapPainter(
          nodes: nodes,
          relations: relations,
          viewportSize: viewportSize,
          margins: margins,
          visibleRect: Rect.zero,
          primaryColor: primaryColor,
        ),
      ),
    );
  }
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
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.viewportLeft != viewportLeft ||
        oldDelegate.viewportTop != viewportTop ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.viewportHeight != viewportHeight;
  }
}
