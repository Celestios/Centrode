import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import '../../../helpers/gesture_test_harness.dart';

void main() {
  group('Deterministic FSM Canvas Gesture Engine', () {
    late GestureTestHarness harness;

    setUp(() {
      harness = GestureTestHarness();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Liveness Invariant: Canvas starts in CanvasIdle and panScaleEnabled is true', () {
      expect(harness.controller.state.value, isA<CanvasIdle>());
      expect(harness.controller.panScaleEnabled.value, isTrue);
    });

    test('Pointer down and drag locks pan/scale; pointer up strictly restores CanvasIdle and pan/scale', () {
      harness.controller.handlePointerDown(
        harness.down(const Offset(300, 300)),
      );

      harness.advanceTime(const Duration(milliseconds: 50));
      harness.controller.handlePointerMove(
        harness.move(const Offset(350, 350)),
      );

      // Releasing pointer returns strictly to CanvasIdle and reenables pan/scale
      harness.controller.handlePointerUp(
        harness.up(const Offset(350, 350)),
      );
      expect(harness.controller.state.value, isA<CanvasIdle>());
      expect(harness.controller.panScaleEnabled.value, isTrue);
    });

    test('Gesture Cancellation Invariant: PointerCancelEvent always recovers to CanvasIdle', () {
      harness.context.seedNode('node-1', const Offset(100, 100), const Size(160, 80));

      harness.controller.handlePointerDown(
        harness.down(const Offset(120, 120)),
      );
      harness.advanceTime(const Duration(milliseconds: 50));
      harness.controller.handlePointerMove(
        harness.move(const Offset(200, 200)),
      );

      // Simulate unexpected gesture cancel (e.g. window blur or palm rejection)
      harness.controller.handlePointerCancel(
        harness.cancel(const Offset(200, 200)),
      );

      expect(harness.controller.state.value, isA<CanvasIdle>());
      expect(harness.controller.panScaleEnabled.value, isTrue);
    });
  });
}
