part of '../base_interaction_state.dart';

final Logger _optAreaLog = Logger('OptAreaDrawing');

/// State when dragging an OptArea box via left-click on empty space in 'optimize' tool mode.
class OptAreaDrawing extends CanvasInteractionState {
  final Offset startPos;
  final Offset currentPos;

  const OptAreaDrawing(this.startPos, this.currentPos);

  @override
  bool get allowsAutoPan => true;

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    return OptAreaDrawing(startPos, pCanvas);
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final optRect = Rect.fromPoints(startPos, currentPos);
    _optAreaLog.info('OptArea Defined: $optRect');
    if (optRect.width.abs() < 5 || optRect.height.abs() < 5) {
      ctx.onSetOptArea(null);
    } else {
      ctx.onSetOptArea(optRect);
    }
    ctx.setToolMode('select');
    return const CanvasIdle();
  }
}
