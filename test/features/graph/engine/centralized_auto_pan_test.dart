import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockInteractionContext extends Mock implements InteractionContext {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

void main() {
  setUpAll(() {
    registerFallbackValue(Offset.zero);
    registerFallbackValue(RawUuid.fromString('fallback-id'));
  });

  group('Centralized InteractionController Auto-Pan', () {
    late MockInteractionContext mockEnv;
    late MockRelationEngineState mockEngine;
    late TransformationController transformController;
    late InteractionController controller;

    setUp(() {
      mockEnv = MockInteractionContext();
      mockEngine = MockRelationEngineState();
      transformController = TransformationController();

      when(() => mockEnv.viewportSize).thenReturn(const Size(1000, 800));
      when(() => mockEnv.currentScale).thenReturn(1.0);
      when(() => mockEnv.panViewport(any())).thenReturn(null);
      when(() => mockEnv.screenToCanvas(any()))
          .thenAnswer((i) => i.positionalArguments.first as Offset);
      when(() => mockEnv.setHoveredNodeMetadata(any())).thenReturn(null);
      when(() => mockEnv.setHoveredPort(any())).thenReturn(null);
      when(() => mockEnv.zOrder).thenReturn([]);
      when(() => mockEnv.getVisibleNodeIds()).thenReturn({});
      when(() => mockEnv.nodeViewStates).thenReturn({});
      when(() => mockEnv.getRelations()).thenReturn([]);
      when(() => mockEnv.onSelectEntities(any())).thenReturn(null);
      when(() => mockEnv.onCreateNode(any())).thenReturn(RawUuid.fromString('new-node'));
      when(() => mockEnv.onRelationCreate(any(), any(), fromSide: any(named: 'fromSide'), toSide: any(named: 'toSide'), verb: any(named: 'verb'))).thenReturn(null);
      when(() => mockEnv.onRelationSnapPreviewClear(any())).thenReturn(null);
      when(() => mockEnv.relationEngine).thenReturn(mockEngine);
      when(() => mockEngine.cache).thenReturn({});

      controller = InteractionController(
        transformController: transformController,
        environment: mockEnv,
      );
    });

    tearDown(() {
      controller.state.value = const CanvasIdle();
      controller.dispose();
      transformController.dispose();
    });

    test('allowsAutoPan flags are enabled on all interactive drag/draw states', () {
      expect(const CanvasIdle().allowsAutoPan, isFalse);
      expect(NodeDragging(RawUuid.fromString('n1'), Offset.zero).allowsAutoPan, isTrue);
      expect(
        GroupDragging(
          nodeIds: [RawUuid.fromString('n1')],
          anchorNodeId: RawUuid.fromString('n1'),
          grabOffset: Offset.zero,
          originalPositions: {RawUuid.fromString('n1'): Offset.zero},
        ).allowsAutoPan,
        isTrue,
      );
      expect(const MarqueeSelecting(Offset.zero, Offset.zero).allowsAutoPan, isTrue);
      expect(const OptAreaDrawing(Offset.zero, Offset.zero).allowsAutoPan, isTrue);
      expect(
        const OptAreaResizing(
          edge: OptAreaResizeEdge.right,
          initialRect: Rect.zero,
          startPos: Offset.zero,
        ).allowsAutoPan,
        isTrue,
      );
      expect(const RelationDrawing({}, Offset.zero).allowsAutoPan, isTrue);
      expect(
        RelationTipDragging(
          relationId: RawUuid.fromString('r1'),
          isStartTip: true,
          originalPosition: Offset.zero,
          currentCursorPosition: Offset.zero,
        ).allowsAutoPan,
        isTrue,
      );
    });

    testWidgets('triggers panViewport when dragging Marquee near right edge', (tester) async {
      controller.state.value = const MarqueeSelecting(Offset(100, 100), Offset(100, 100));

      controller.handlePointerMove(
        const PointerMoveEvent(position: Offset(980, 400)),
      );

      await tester.pump(const Duration(milliseconds: 32));

      verify(() => mockEnv.panViewport(any(that: predicate<Offset>((o) => o.dx < 0)))).called(greaterThan(0));

      controller.handlePointerUp(const PointerUpEvent(position: Offset(980, 400)));
    });

    testWidgets('triggers panViewport when drawing Relation near bottom edge', (tester) async {
      when(() => mockEnv.getRelations()).thenReturn([]);
      when(() => mockEnv.nodeViewStates).thenReturn({});
      when(() => mockEnv.setHoveredNode(any())).thenReturn(null);
      when(() => mockEnv.onNodeDragUpdate()).thenReturn(null);

      controller.state.value = RelationDrawing(
        {RawUuid.fromString('n1')},
        const Offset(100, 100),
      );

      controller.handlePointerMove(
        const PointerMoveEvent(position: Offset(500, 780)),
      );

      await tester.pump(const Duration(milliseconds: 32));

      verify(() => mockEnv.panViewport(any(that: predicate<Offset>((o) => o.dy < 0)))).called(greaterThan(0));

      controller.handlePointerUp(const PointerUpEvent(position: Offset(500, 780)));
    });

    testWidgets('stops auto-pan immediately when pointer released', (tester) async {
      controller.state.value = const MarqueeSelecting(Offset(100, 100), Offset(100, 100));
      controller.handlePointerMove(
        const PointerMoveEvent(position: Offset(980, 400)),
      );

      controller.handlePointerUp(
        const PointerUpEvent(position: Offset(980, 400)),
      );

      reset(mockEnv);
      when(() => mockEnv.viewportSize).thenReturn(const Size(1000, 800));

      await tester.pump(const Duration(milliseconds: 50));

      verifyNever(() => mockEnv.panViewport(any()));
    });
  });
}
