// lib/features/graph/state/canvas_interaction_states.dart
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../engine/config.dart';
import '../models/models.dart';
import '../models/port.dart';
import '../presentation/strategies/node_layout_strategy.dart';
import 'interaction_context.dart';
import 'hit_test_resolver.dart';
import 'z_order_utils.dart';
import 'package:centrode/src/rust/domain/routing.dart' as rust_geo;

part 'states/idle_state.dart';
part 'states/node_drag_state.dart';
part 'states/group_drag_state.dart';
part 'states/relation_draw_state.dart';
part 'states/node_resize_state.dart';
part 'states/toolbar_drag_state.dart';
part 'states/marquee_state.dart';
part 'states/relation_tip_drag_state.dart';
part 'states/opt_area_draw_state.dart';
part 'states/opt_area_resize_state.dart';
part 'states/frame_draw_state.dart';
part 'states/auto_pan_manager.dart';
part 'states/snap_utils.dart';

final Logger _snapLog = Logger('GridSnapping');

/// O(1) Mathematical quantization for continuous grid snapping.
Offset _snapToGrid(Offset p, double gridSize) {
  final snapped = Offset(
    (p.dx / gridSize).round() * gridSize,
    (p.dy / gridSize).round() * gridSize,
  );
  _snapLog.finest('Grid snap: $p -> $snapped (grid: $gridSize)');
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

  /// Whether camera auto-panning is active when dragging near viewport edges.
  bool get allowsAutoPan => false;

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
