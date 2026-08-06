part of '../base_interaction_state.dart';

final Logger _optAreaLog = Logger('OptAreaDrawing');

/// State when dragging an OptArea box via left-click on empty space in 'optimize' tool mode.
class OptAreaDrawing extends CanvasInteractionState {
  final Offset startPos;
  final Offset currentPos;

  const OptAreaDrawing(this.startPos, this.currentPos);

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
    ctx.onSetOptArea(optRect);
    return const CanvasIdle();
  }
}
