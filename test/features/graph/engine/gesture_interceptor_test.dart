import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/engine/gesture_interceptor.dart';
import 'package:mycelium/features/graph/engine/interaction_context.dart';
import 'package:mycelium/features/graph/engine/interaction_engine.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

import 'package:mycelium/features/graph/engine/drawing_interceptor.dart';
import 'package:mycelium/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';

import 'package:mycelium/features/graph/store/relation_engine_state.dart';
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class MockInteractionContext extends Mock implements InteractionContext {}
class MockTabSession extends Mock implements TabSession {}
class MockViewportController extends Mock implements ViewportController {}
class MockRelationEngineState extends Mock implements RelationEngineState {}

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
    registerFallbackValue(Size.zero);
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
      when(() => mockEnv.getSelectedEntities()).thenReturn(<RawUuid>{});
      when(() => mockEnv.getRelations()).thenReturn(<UiRelation>[]);
      when(() => mockEnv.zOrder).thenReturn(<RawUuid>[]);
      when(() => mockEnv.nodeViewStates).thenReturn(<RawUuid, NodeViewState>{});
      final mockRelationEngine = MockRelationEngineState();
      when(() => mockRelationEngine.cache).thenReturn(<RawUuid, ComputedRelation>{});
      when(() => mockEnv.relationEngine).thenReturn(mockRelationEngine);
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

  group('DrawingGestureInterceptor Tests', () {
    late InteractionController controller;
    late MockInteractionContext mockEnv;
    late MockTabSession mockSession;
    late MockViewportController mockViewport;
    late TransformationController transformController;
    late DrawingGestureInterceptor interceptor;

    late ValueNotifier<String> toolModeNotifier;
    late ValueNotifier<String> brushColorNotifier;
    late ValueNotifier<double> brushThicknessNotifier;
    late ValueNotifier<String> brushTypeNotifier;

    setUp(() {
      mockEnv = MockInteractionContext();
      mockSession = MockTabSession();
      mockViewport = MockViewportController();
      transformController = TransformationController();
      controller = InteractionController(
        transformController: transformController,
        environment: mockEnv,
      );

      toolModeNotifier = ValueNotifier<String>('select');
      brushColorNotifier = ValueNotifier<String>('#00E5FF');
      brushThicknessNotifier = ValueNotifier<double>(4.0);
      brushTypeNotifier = ValueNotifier<String>('pen');

      // Stub environment calls since FSM CanvasIdle handlePointerDown will run when bubbling
      when(() => mockEnv.getActiveEditId()).thenReturn(null);
      when(() => mockEnv.getSelectedEntities()).thenReturn(<RawUuid>{});
      when(() => mockEnv.getRelations()).thenReturn(<UiRelation>[]);
      when(() => mockEnv.zOrder).thenReturn(<RawUuid>[]);
      when(() => mockEnv.nodeViewStates).thenReturn(<RawUuid, NodeViewState>{});
      final mockRelationEngine = MockRelationEngineState();
      when(() => mockRelationEngine.cache).thenReturn(<RawUuid, ComputedRelation>{});
      when(() => mockEnv.relationEngine).thenReturn(mockRelationEngine);
      when(() => mockEnv.onSelectEntity(any())).thenAnswer((_) {});

      when(() => mockSession.toolModeNotifier).thenReturn(toolModeNotifier);
      when(() => mockSession.brushColorNotifier).thenReturn(brushColorNotifier);
      when(() => mockSession.brushThicknessNotifier).thenReturn(brushThicknessNotifier);
      when(() => mockSession.brushTypeNotifier).thenReturn(brushTypeNotifier);
      when(() => mockViewport.transformController).thenReturn(transformController);

      interceptor = DrawingGestureInterceptor(
        session: mockSession,
        viewportController: mockViewport,
      );
      controller.registerInterceptor(interceptor);
    });

    tearDown(() {
      interceptor.dispose();
      toolModeNotifier.dispose();
      brushColorNotifier.dispose();
      brushThicknessNotifier.dispose();
      brushTypeNotifier.dispose();
    });

    test('ignores pointer events when tool mode is not draw', () {
      toolModeNotifier.value = 'select';
      const event = PointerDownEvent(position: Offset(10, 20), buttons: kPrimaryMouseButton);

      controller.handlePointerDown(event);

      expect(interceptor.activeStroke.value, isEmpty);
    });

    test('captures and consumes pointer events when tool mode is draw', () {
      toolModeNotifier.value = 'draw';
      
      const downEvent = PointerDownEvent(position: Offset(10, 20), buttons: kPrimaryMouseButton);
      controller.handlePointerDown(downEvent);
      expect(interceptor.activeStroke.value, equals([const Offset(10, 20)]));

      const moveEvent = PointerMoveEvent(position: Offset(15, 25));
      controller.handlePointerMove(moveEvent);
      expect(interceptor.activeStroke.value, equals([const Offset(10, 20), const Offset(15, 25)]));
    });

    test('creates drawing node on pointer up', () {
      toolModeNotifier.value = 'draw';
      
      // Setup down and move first
      controller.handlePointerDown(const PointerDownEvent(position: Offset(10, 20), buttons: kPrimaryMouseButton));
      controller.handlePointerMove(const PointerMoveEvent(position: Offset(30, 40)));

      // Stub onCreateDrawingNode
      when(() => mockEnv.onCreateDrawingNode(
        position: any(named: 'position'),
        paths: any(named: 'paths'),
        brushType: any(named: 'brushType'),
        brushThickness: any(named: 'brushThickness'),
        brushColor: any(named: 'brushColor'),
        size: any(named: 'size'),
      )).thenAnswer((_) {});

      // Trigger pointer up
      controller.handlePointerUp(const PointerUpEvent(position: Offset(30, 40)));

      // Verify that onCreateDrawingNode was called on the environment
      verify(() => mockEnv.onCreateDrawingNode(
        position: const Offset(10 - 12.0, 20 - 12.0), // padding is 12.0
        paths: ['12.0,12.0;32.0,32.0'],
        brushType: 'pen',
        brushThickness: 4.0,
        brushColor: '#00E5FF',
        size: const Size(20 + 24.0, 20 + 24.0), // 30-10=20 width + 24 padding
      )).called(1);

      // Verify activeStroke is cleared
      expect(interceptor.activeStroke.value, isEmpty);
    });

    test('cancels active drawing stroke on pointer cancel', () {
      toolModeNotifier.value = 'draw';
      controller.handlePointerDown(const PointerDownEvent(position: Offset(10, 20), buttons: kPrimaryMouseButton));
      expect(interceptor.activeStroke.value, isNotEmpty);

      controller.handlePointerCancel(const PointerCancelEvent());
      expect(interceptor.activeStroke.value, isEmpty);
    });
  });
}
