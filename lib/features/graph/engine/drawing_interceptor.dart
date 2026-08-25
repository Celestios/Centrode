import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'gesture_interceptor.dart';
import 'interaction_context.dart';
import 'canvas_tool_mode.dart';
import '../presentation/workspace_tabs_controller.dart';
import '../presentation/viewport_state.dart';

/// Interceptor that handles drawing gesture events in canvas space.
///
/// Captures down, move, up, and cancel pointer events while drawing mode is active,
/// maintaining an in-memory stroke list and converting coordinates into canvas space.
/// Triggers drawing node creation upon gesture cycle completion.
class DrawingGestureInterceptor extends GestureInterceptor {
  final Logger _log = Logger('DrawingGestureInterceptor');
  final TabSession session;
  final ViewportController viewportController;

  /// Exposes the active drawing stroke so the UI layer can paint it.
  final ValueNotifier<List<Offset>> activeStroke = ValueNotifier([]);

  DrawingGestureInterceptor({
    required this.session,
    required this.viewportController,
  });

  bool get isDrawingActive =>
      CanvasToolMode.fromString(session.toolModeNotifier.value).isDraw;

  Offset _getLocalCanvasCoords(Offset localPosition) {
    final transform = viewportController.transformController.value;
    if (transform.determinant() == 0.0) return localPosition;
    final inverse = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(inverse, localPosition);
  }

  @override
  InterceptorDisposition onPointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    if (isDrawingActive && e.buttons == kPrimaryMouseButton) {
      _log.fine('onPointerDown: drawing started');
      activeStroke.value = [_getLocalCanvasCoords(e.localPosition)];
      return InterceptorDisposition.consumed;
    }
    return InterceptorDisposition.bubble;
  }

  @override
  InterceptorDisposition onPointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    if (isDrawingActive && activeStroke.value.isNotEmpty) {
      final currentPoint = _getLocalCanvasCoords(e.localPosition);
      final type = session.brushTypeNotifier.value;
      final currentList = List<Offset>.from(activeStroke.value);
      if (type == 'line') {
        if (currentList.isNotEmpty) {
          activeStroke.value = [currentList.first, currentPoint];
        } else {
          activeStroke.value = [currentPoint];
        }
      } else {
        activeStroke.value = currentList..add(currentPoint);
      }
      return InterceptorDisposition.consumed;
    }
    return InterceptorDisposition.bubble;
  }

  @override
  InterceptorDisposition onPointerUp(PointerUpEvent e, InteractionContext ctx) {
    if (isDrawingActive && activeStroke.value.isNotEmpty) {
      _endDrawing(ctx);
      return InterceptorDisposition.consumed;
    }
    return InterceptorDisposition.bubble;
  }

  @override
  InterceptorDisposition onPointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) {
    if (isDrawingActive && activeStroke.value.isNotEmpty) {
      _cancelDrawing();
      return InterceptorDisposition.consumed;
    }
    return InterceptorDisposition.bubble;
  }

  void _endDrawing(InteractionContext ctx) {
    final stroke = activeStroke.value;
    _log.info('_endDrawing: stroke points=${stroke.length}');
    if (stroke.length < 2) {
      _cancelDrawing();
      return;
    }

    double minX = stroke.first.dx;
    double maxX = stroke.first.dx;
    double minY = stroke.first.dy;
    double maxY = stroke.first.dy;

    for (final p in stroke) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    _log.fine('_endDrawing: bounds=($minX,$minY)-($maxX,$maxY)');
    final width = maxX - minX;
    final height = maxY - minY;

    if (width < 2 && height < 2) {
      _cancelDrawing();
      return;
    }

    const padding = 12.0;
    final normalizedPoints = stroke
        .map((p) {
          final rx = p.dx - minX + padding;
          final ry = p.dy - minY + padding;
          return '${rx.toStringAsFixed(1)},${ry.toStringAsFixed(1)}';
        })
        .join(';');

    final nodePosition = Offset(minX - padding, minY - padding);
    final nodeSize = Size(width + padding * 2, height + padding * 2);

    final brushColor = session.brushColorNotifier.value;
    final brushThickness = session.brushThicknessNotifier.value;
    final brushType = session.brushTypeNotifier.value;

    ctx.onCreateDrawingNode(
      position: nodePosition,
      paths: [normalizedPoints],
      brushType: brushType,
      brushThickness: brushThickness,
      brushColor: brushColor,
      size: nodeSize,
    );

    _cancelDrawing();
  }

  void _cancelDrawing() {
    _log.fine('_cancelDrawing');
    activeStroke.value = [];
  }

  void dispose() {
    activeStroke.dispose();
  }
}
