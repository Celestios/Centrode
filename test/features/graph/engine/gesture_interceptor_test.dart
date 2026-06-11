import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/engine/gesture_interceptor.dart';
import 'package:mycelium/features/graph/engine/interaction_context.dart';
import 'package:mycelium/features/graph/engine/interaction_engine.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

class MockInteractionContext extends Mock implements InteractionContext {}

class TestInterceptor extends GestureInterceptor {
  final InterceptorDisposition returnDisposition;
  int callCount = 0;
  PointerDownEvent? lastDownEvent;
  PointerMoveEvent? lastMoveEvent;
  PointerUpEvent? lastUpEvent;
  PointerHoverEvent? lastHoverEvent;

  TestInterceptor({required this.returnDisposition});

  @override
  InterceptorDisposition onPointerDown(
    PointerDownEvent e,
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    callCount++;
    lastDownEvent = e;
    return returnDisposition;
  }

  @override
  InterceptorDisposition onPointerMove(
    PointerMoveEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    callCount++;
    lastMoveEvent = e;
    return returnDisposition;
  }

  @override
  InterceptorDisposition onPointerUp(
    PointerUpEvent e,
    InteractionContext ctx,
  ) {
    callCount++;
    lastUpEvent = e;
    return returnDisposition;
  }

  @override
  InterceptorDisposition onPointerHover(
    PointerHoverEvent e,
    Offset pCanvas,
    InteractionContext ctx,
  ) {
    callCount++;
    lastHoverEvent = e;
    return returnDisposition;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const PointerDownEvent());
    registerFallbackValue(const PointerMoveEvent());
    registerFallbackValue(const PointerUpEvent());
    registerFallbackValue(const PointerHoverEvent());
    registerFallbackValue(Offset.zero);
  });

  group('GestureInterceptor Chain Tests', () {
    late InteractionController controller;
    late MockInteractionContext mockEnv;
    late TransformationController transformController;

    setUp(() {
      mockEnv = MockInteractionContext();
      transformController = TransformationController();
      controller = InteractionController(
        transformController: transformController,
        environment: mockEnv,
      );

      // Stub environment calls since FSM CanvasIdle handlePointerDown will run
      when(() => mockEnv.getActiveEditId()).thenReturn(null);
      when(() => mockEnv.getSelectedEntities()).thenReturn(<String>{});
      when(() => mockEnv.getRelations()).thenReturn(<UiRelation>[]);
      when(() => mockEnv.zOrder).thenReturn(<String>[]);
      when(() => mockEnv.nodeViewStates).thenReturn(<String, NodeViewState>{});
      when(() => mockEnv.relationPathCache).thenReturn(<String, List<Offset>>{});
      when(() => mockEnv.onSelectEntity(any())).thenAnswer((_) {});
    });

    test('Events bubble through multiple interceptors in order', () {
      final interceptor1 = TestInterceptor(returnDisposition: InterceptorDisposition.bubble);
      final interceptor2 = TestInterceptor(returnDisposition: InterceptorDisposition.bubble);

      controller.registerInterceptor(interceptor1);
      controller.registerInterceptor(interceptor2);



      const event = PointerDownEvent(position: Offset(10, 20));
      controller.handlePointerDown(event);

      expect(interceptor1.callCount, 1);
      expect(interceptor2.callCount, 1);
      expect(interceptor1.lastDownEvent?.position, const Offset(10, 20));
      expect(interceptor2.lastDownEvent?.position, const Offset(10, 20));
    });

    test('Consumption halts propagation down the chain and bypasses FSM state', () {
      final interceptor1 = TestInterceptor(returnDisposition: InterceptorDisposition.consumed);
      final interceptor2 = TestInterceptor(returnDisposition: InterceptorDisposition.bubble);

      controller.registerInterceptor(interceptor1);
      controller.registerInterceptor(interceptor2);

      const event = PointerDownEvent(position: Offset(10, 20));
      controller.handlePointerDown(event);

      // Interceptor 1 consumes it
      expect(interceptor1.callCount, 1);
      // Interceptor 2 is skipped
      expect(interceptor2.callCount, 0);
      // FSM state is not invoked, so environment (mockEnv) is never accessed
      verifyZeroInteractions(mockEnv);
    });

    test('Unregistering an interceptor stops it from receiving events', () {
      final interceptor = TestInterceptor(returnDisposition: InterceptorDisposition.bubble);

      controller.registerInterceptor(interceptor);
      controller.unregisterInterceptor(interceptor);

      const event = PointerDownEvent();
      controller.handlePointerDown(event);

      expect(interceptor.callCount, 0);
    });
  });
}
