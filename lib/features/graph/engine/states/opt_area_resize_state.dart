part of '../base_interaction_state.dart';

final Logger _optAreaResizeLog = Logger('OptAreaResizing');

/// Edge of the OptArea rectangle being dragged for resizing.
enum OptAreaResizeEdge { left, right, top, bottom }

/// Interaction state when dragging one of the 4 side handles of the OptArea rectangle.
class OptAreaResizing extends CanvasInteractionState {
  final OptAreaResizeEdge edge;
  final Rect initialRect;
  final Offset startPos;

  const OptAreaResizing({
    required this.edge,
    required this.initialRect,
    required this.startPos,
  });

  @override
  bool get allowsAutoPan => true;

  @override
  MouseCursor get cursor {
    switch (edge) {
      case OptAreaResizeEdge.left:
      case OptAreaResizeEdge.right:
        return SystemMouseCursors.resizeLeftRight;
      case OptAreaResizeEdge.top:
      case OptAreaResizeEdge.bottom:
        return SystemMouseCursors.resizeUpDown;
    }
  }

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    final delta = pCanvas - startPos;
    double left = initialRect.left;
    double top = initialRect.top;
    double right = initialRect.right;
    double bottom = initialRect.bottom;

    const minSize = 20.0;

    switch (edge) {
      case OptAreaResizeEdge.left:
        left = (initialRect.left + delta.dx)
            .clamp(double.negativeInfinity, right - minSize);
        break;
      case OptAreaResizeEdge.right:
        right = (initialRect.right + delta.dx)
            .clamp(left + minSize, double.infinity);
        break;
      case OptAreaResizeEdge.top:
        top = (initialRect.top + delta.dy)
            .clamp(double.negativeInfinity, bottom - minSize);
        break;
      case OptAreaResizeEdge.bottom:
        bottom = (initialRect.bottom + delta.dy)
            .clamp(top + minSize, double.infinity);
        break;
    }

    final newRect = Rect.fromLTRB(left, top, right, bottom);
    ctx.onSetOptArea(newRect, commitToBackend: false);
    return this;
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    _optAreaResizeLog.info('OptArea Resize Complete: ${ctx.optArea}');
    if (ctx.optArea != null) {
      ctx.onSetOptArea(ctx.optArea, commitToBackend: true);
    }
    return const CanvasIdle();
  }

  @override
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) {
    return const CanvasIdle();
  }
}
