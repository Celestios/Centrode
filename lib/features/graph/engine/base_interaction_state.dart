// lib/features/graph/state/canvas_interaction_states.dart
library;

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../presentation/graph_metrics.dart';
import '../presentation/strategies/relation_layout_strategy.dart';
import '../presentation/strategies/routing/relation_layout_context.dart';
import '../models/models.dart';
import 'interaction_context.dart';

part 'states/idle_state.dart';
part 'states/node_drag_state.dart';
part 'states/group_drag_state.dart';
part 'states/relation_draw_state.dart';
part 'states/node_resize_state.dart';
part 'states/toolbar_drag_state.dart';
part 'states/marquee_state.dart';
part 'states/relation_tip_drag_state.dart';

/// Calculates the dynamic grid size based on the current zoom level (Dynamic LOD).
double calculateEffectiveGridSize(double scale) {
  if (scale <= 0) return AppConfig.grid.baseSize;
  final double lod = max(1.0, (1.0 / scale).floorToDouble());
  final effectiveSize = AppConfig.grid.baseSize * lod;
  return effectiveSize;
}

/// O(1) Mathematical quantization for continuous grid snapping.
Offset _snapToGrid(Offset p, double gridSize) {
  final snapped = Offset(
    (p.dx / gridSize).round() * gridSize,
    (p.dy / gridSize).round() * gridSize,
  );
  return snapped;
}

/// Sealed base class for all canvas interaction states.
///
/// Implements the Gang of Four (GoF) State Pattern where each subclass
/// encapsulates specialized domain physics. The sealed modifier enables
/// exhaustive pattern matching for state transitions.
///
/// Each state handles its own event processing and returns the next state,
/// enabling polymorphic dispatch without switch statements in the controller.
sealed class CanvasInteractionState {
  const CanvasInteractionState();

  /// The mouse cursor associated with this state.
  MouseCursor get cursor => SystemMouseCursors.basic;

  /// Handles pointer down events. Returns the next state after processing.
  /// Default implementation returns `this` (no state change).
  CanvasInteractionState handlePointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) => this;

  /// Handles pointer move events. Returns the next state after processing.
  /// Default implementation returns `this` (no state change).
  CanvasInteractionState handlePointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) => this;

  /// Handles pointer up events. Returns the next state after processing.
  /// Default implementation returns to [CanvasIdle].
  CanvasInteractionState handlePointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) => const CanvasIdle();

  /// Handles pointer cancel events. Returns the next state after processing.
  /// Default implementation returns to [CanvasIdle].
  CanvasInteractionState handlePointerCancel(
    PointerCancelEvent e,
    InteractionContext ctx,
  ) => const CanvasIdle();

  /// Handles pointer hover events. Returns the next state after processing.
  /// Default implementation returns `this` (no state change) for O(1) fast-fail.
  CanvasInteractionState handlePointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) => this;
}
