import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:logging/logging.dart';
import '../presentation/graph_metrics.dart';
import 'base_interaction_state.dart';
import 'interaction_context.dart';

/// The Interaction Controller (FSM Engine)
///
/// This engine circumvents the Gesture Arena by processing raw PointerEvents.
/// It centralizes all pointer events into a math-driven FSM that operates in
/// canvas space, decoupling user intent from the Flutter Widget tree.
///
/// Implements the GoF State Pattern where state objects handle their own
/// event processing, enabling polymorphic dispatch without switch statements.
///
/// The controller now takes an [InteractionContext] environment
/// instead of implementing it directly, ensuring a strict boundary between
/// the FSM engine and the data/UI layers.
class InteractionController {
  final Logger _log = Logger('InteractionController');

  /// The current interaction state of the canvas.
  final ValueNotifier<CanvasInteractionState> state = ValueNotifier(
    const CanvasIdle(),
  );

  /// Controller for canvas transformations (pan/zoom).
  final TransformationController transformController;

  /// The external environment providing data and capabilities to the FSM.
  final InteractionContext environment;

  // Double-tap detection state
  DateTime? _lastPointerDownTime;
  Offset? _lastPointerDownPos;

  InteractionController({
    required this.transformController,
    required this.environment,
  });

  // ---------------------------------------------------------------------------
  // FSM Engine
  // ---------------------------------------------------------------------------

  /// Centralized state mutation to guarantee FSM observability.
  /// Logs state transitions for telemetry and debugging purposes.
  void _transitionTo(CanvasInteractionState newState) {
    if (state.value.runtimeType != newState.runtimeType) {
      _log.fine(
        'FSM Transition: ${state.value.runtimeType} -> ${newState.runtimeType}',
      );
    }
    state.value = newState;
  }

  /// Converts a screen position to canvas coordinates.
  Offset _screenToCanvas(Offset screenPos) {
    final transform = transformController.value;

    // Guard against singular matrix (scale = 0)
    if (transform.determinant() == 0.0) return screenPos;

    return MatrixUtils.transformPoint(Matrix4.inverted(transform), screenPos);
  }

  /// Processes double-tap detection and returns true if this is a double-tap.
  bool _processDoubleTap(Offset pCanvas) {
    final now = DateTime.now();
    bool isDoubleTap = false;

    if (_lastPointerDownTime != null &&
        now.difference(_lastPointerDownTime!).inMilliseconds <
            AppConfig.interaction.doubleTapMs &&
        _lastPointerDownPos != null &&
        (_lastPointerDownPos! - pCanvas).distance <
            AppConfig.interaction.doubleTapDistance) {
      isDoubleTap = true;
    }

    _lastPointerDownTime = now;
    _lastPointerDownPos = pCanvas;

    return isDoubleTap;
  }

  /// Handles pointer down events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerDown method.
  void handlePointerDown(PointerDownEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    final isDoubleTap = _processDoubleTap(pCanvas);

    // Telemetry for input origin and double-tap detection
    _log.finer(
      'PointerDown: Screen(${e.localPosition.dx.toInt()}, ${e.localPosition.dy.toInt()}) -> Canvas(${pCanvas.dx.toInt()}, ${pCanvas.dy.toInt()})',
    );
    if (isDoubleTap) _log.info('Double-tap detected at $pCanvas');

    // Polymorphic dispatch to state object, passing the isolated environment facade
    final newState = state.value.handlePointerDown(
      e,
      pCanvas,
      environment,
      isDoubleTap,
    );
    _transitionTo(newState);
  }

  /// Handles pointer move events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerMove method.
  void handlePointerMove(PointerMoveEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    _transitionTo(state.value.handlePointerMove(e, pCanvas, environment));
  }

  /// Handles pointer up events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerUp method.
  void handlePointerUp(PointerUpEvent e) {
    _log.finer(
      'PointerUp: Gesture cycle complete at Canvas(${e.localPosition.dx}, ${e.localPosition.dy})',
    );
    _transitionTo(state.value.handlePointerUp(e, environment));
  }

  /// Handles pointer cancel events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerCancel method.
  void handlePointerCancel(PointerCancelEvent e) {
    _log.warning('Pointer event cancelled by OS. Resetting FSM to Idle.');
    _transitionTo(state.value.handlePointerCancel(e, environment));
  }

  /// Handles pointer hover events with polymorphic dispatch.
  /// Fast-fails (O(1)) for most states, consumes (O(N)) for specific tools.
  void handlePointerHover(PointerHoverEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    _transitionTo(state.value.handlePointerHover(e, pCanvas, environment));
  }

  /// Disposes the state notifier.
  void dispose() {
    state.dispose();
  }
}
