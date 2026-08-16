part of '../base_interaction_state.dart';

final Logger _frameDrawLog = Logger('FrameDrawing');

/// State when dragging to draw a Frame on the canvas in 'frame' tool mode.
class FrameDrawing extends CanvasInteractionState {
  final Offset startPos;
  final Offset currentPos;

  const FrameDrawing(this.startPos, this.currentPos);

  @override
  bool get allowsAutoPan => true;

  @override
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    return FrameDrawing(startPos, pCanvas);
  }

  @override
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    final rawRect = Rect.fromPoints(startPos, currentPos);
    final rect = Rect.fromLTRB(
      math.min(rawRect.left, rawRect.right),
      math.min(rawRect.top, rawRect.bottom),
      math.max(rawRect.left, rawRect.right),
      math.max(rawRect.top, rawRect.bottom),
    );
    _frameDrawLog.info('Frame Drawn: $rect');

    if (rect.width >= 30 && rect.height >= 30) {
      final parentContainerId = ctx.activeScope is ContainerViewportScope
          ? (ctx.activeScope as ContainerViewportScope).containerId
          : null;
      ctx.onCreateFrame(
        rect.topLeft,
        rect.size,
        parentContainerId: parentContainerId,
      );
    }

    ctx.setToolMode('select');
    return const CanvasIdle();
  }
}
