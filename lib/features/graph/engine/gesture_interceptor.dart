import 'package:flutter/gestures.dart';
import 'interaction_context.dart';

/// The result of an interceptor's pointer event handling.
enum InterceptorDisposition {
  /// The event has been fully handled; halt propagation down the chain.
  consumed,

  /// The event was ignored or partially handled; pass it down the chain.
  bubble,
}

/// A modular extension point to intercept canvas gestures.
///
/// Implement this class and register it via `InteractionController.registerInterceptor`
/// to capture pointer events before they reach the main FSM.
abstract class GestureInterceptor {
  const GestureInterceptor();

  InterceptorDisposition onPointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) =>
      InterceptorDisposition.bubble;

  InterceptorDisposition onPointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) =>
      InterceptorDisposition.bubble;

  InterceptorDisposition onPointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) =>
      InterceptorDisposition.bubble;

  InterceptorDisposition onPointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) =>
      InterceptorDisposition.bubble;

  InterceptorDisposition onPointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) =>
      InterceptorDisposition.bubble;
}
