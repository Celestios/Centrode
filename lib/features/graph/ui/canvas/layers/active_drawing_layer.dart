import 'package:flutter/material.dart';
import '../../../engine/drawing_interceptor.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import '../painters/active_drawing_painter.dart';

/// Standalone display layer for rendering high-frequency 120Hz freehand strokes.
/// Wrapped in a RepaintBoundary to isolate active stroke additions from dirtying
/// the underlying canvas display lists or glass downsample buffers.
class ActiveDrawingLayer extends StatefulWidget {
  final DrawingGestureInterceptor? drawingInterceptor;
  final TabSession session;

  const ActiveDrawingLayer({
    super.key,
    required this.drawingInterceptor,
    required this.session,
  });

  @override
  State<ActiveDrawingLayer> createState() => _ActiveDrawingLayerState();
}

class _ActiveDrawingLayerState extends State<ActiveDrawingLayer> {
  Listenable? _listenable;

  @override
  void initState() {
    super.initState();
    _updateListenable();
  }

  @override
  void didUpdateWidget(ActiveDrawingLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawingInterceptor != widget.drawingInterceptor ||
        oldWidget.session != widget.session) {
      _updateListenable();
    }
  }

  void _updateListenable() {
    final interceptor = widget.drawingInterceptor;
    if (interceptor == null) {
      _listenable = null;
    } else {
      _listenable = Listenable.merge([
        interceptor.activeStroke,
        widget.session.brushColorNotifier,
        widget.session.brushThicknessNotifier,
        widget.session.brushTypeNotifier,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_listenable == null || widget.drawingInterceptor == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: _listenable!,
          builder: (context, _) {
            final stroke = widget.drawingInterceptor!.activeStroke.value;
            if (stroke.isEmpty) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: ActiveDrawingPainter(
                points: stroke,
                brushColor: widget.session.brushColorNotifier.value,
                brushThickness: widget.session.brushThicknessNotifier.value,
                brushType: widget.session.brushTypeNotifier.value,
              ),
            );
          },
        ),
      ),
    );
  }
}
