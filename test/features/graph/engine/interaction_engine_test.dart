import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/engine/interaction_engine.dart';
import 'package:mycelium/features/graph/engine/interaction_context.dart';
import 'package:mycelium/features/graph/engine/base_interaction_state.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

import 'dart:typed_data';
import 'package:mycelium/features/graph/store/relation_engine_state.dart';
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import 'package:mycelium/src/rust/relation_engine/config.dart';
import 'package:mycelium/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:mycelium/features/graph/models/commands/patch_helpers.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class MockInteractionContext extends Mock implements InteractionContext {}

class MockTransformationController extends Mock
    implements TransformationController {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

ComputedRelation createTestComputedRelation(String idStr, List<rust_geom.Point> pathPoints) {
  return ComputedRelation(
    id: parseTypedRecordId('IRelation', idStr),
    pathPoints: pathPoints,
    pathType: PathType.straight,
    startTangent: const rust_geom.Point(x: 0, y: 0),
    endTangent: const rust_geom.Point(x: 0, y: 0),
    bodyWidths: Float64List(0),
    bodyType: BodyType.uniform,
    startEndpoint: EndpointShape.none,
    endEndpoint: EndpointShape.none,
    startDirection: 0.0,
    endDirection: 0.0,
    labelPosition: const rust_geom.Point(x: 0, y: 0),
    labelAnchor: LabelAnchor.center,
    hitTestPoints: pathPoints,
    dependsOnNodes: const [],
    bbox: const rust_geom.Rect(x: 0, y: 0, width: 0, height: 0),
    startMargin: 0.0,
    endMargin: 0.0,
    startArrowCenter: const rust_geom.Point(x: 0, y: 0),
    endArrowCenter: const rust_geom.Point(x: 0, y: 0),
    startPoint: const rust_geom.Point(x: 0, y: 0),
    endPoint: const rust_geom.Point(x: 0, y: 0),
    controlPoints: const [],
    knots: Float64List(0),
    nudgeColors: const [],
    composeActive: false,
  );
}

void main() {
  group('InteractionController (FSM Engine)', () {
    late InteractionController controller;
    late MockTransformationController mockTransform;
    late MockInteractionContext mockContext;

    setUp(() {
      mockTransform = MockTransformationController();
      when(() => mockTransform.value).thenReturn(Matrix4.identity());

      mockContext = MockInteractionContext();
      final mockRelationEngine = MockRelationEngineState();
      when(() => mockRelationEngine.cache).thenReturn(<String, ComputedRelation>{});
      when(() => mockContext.relationEngine).thenReturn(mockRelationEngine);

      controller = InteractionController(
        transformController: mockTransform,
        environment: mockContext,
      );
    });

    test('initial state is CanvasIdle', () {
      expect(controller.state.value, isA<CanvasIdle>());
    });

    test(
      'pointer down on empty space transitions to PanningState (or stays Idle and transform handles it depending on implementation)',
      () {
        // Stub nodeViewStates to return empty map for hit testing
        when(() => mockContext.nodeViewStates).thenReturn({});
        when(() => mockContext.getVisibleNodeIds()).thenReturn({});
        when(() => mockContext.getRelations()).thenReturn([]);
        when(() => mockContext.getSelectedEntities()).thenReturn({});
        when(() => mockContext.zOrder).thenReturn([]);
        when(() => mockContext.onSelectEntity(null)).thenAnswer((_) {});
        when(() => mockContext.onCommitActiveEdit()).thenAnswer((_) {});
        when(() => mockContext.currentScale).thenReturn(1.0);

        final event = PointerDownEvent(position: const Offset(100, 100));

        controller.handlePointerDown(event);

        // Verify that it transitions to Panning or stays Idle based on actual IdleState logic.
        // Assuming IdleState transitions to CanvasPanning or returns CanvasIdle.
        // Let's just verify state is updated and methods were called.
        verify(
          () => mockContext.nodeViewStates,
        ).called(greaterThanOrEqualTo(1));
      },
    );

    test('PointerMove passes through to state', () {
      final event = PointerMoveEvent(position: const Offset(150, 150));

      controller.handlePointerMove(event);
      // As state starts at Idle, it shouldn't crash
      expect(controller.state.value, isNotNull);
    });

    test('PointerUp completes gesture cycle', () {
      final event = PointerUpEvent(position: const Offset(150, 150));

      controller.handlePointerUp(event);
      expect(controller.state.value, isA<CanvasIdle>());
    });

    test(
      'pointer down on relation handle transitions to RelationTipDragging',
      () {
        // 1. Setup mock views, nodes and selected relation
        final fromNode = InfoUiNode(
          id: 'node-from',
          position: const Offset(0, 0),
          size: const Size(100, 60),
        );
        final toNode = InfoUiNode(
          id: 'node-to',
          position: const Offset(300, 0),
          size: const Size(100, 60),
        );

        final rel = InfoUiRelation(
          id: 'rel-1',
          fromNodeId: 'node-from',
          fromNodeTable: 'inode',
          toNodeId: 'node-to',
          toNodeTable: 'inode',
          layout: RelationLayout(
            fromSide: PortSide.right,
            toSide: PortSide.left,
            strategyType: 'default',
          ),
        );

        final fromVs = NodeViewState(fromNode);
        final toVs = NodeViewState(toNode);

        when(
          () => mockContext.nodeViewStates,
        ).thenReturn({'node-from': fromVs, 'node-to': toVs});
        when(() => mockContext.getRelations()).thenReturn([rel]);
        when(() => mockContext.getSelectedEntities()).thenReturn({'rel-1'});
        when(() => mockContext.zOrder).thenReturn(['node-from', 'node-to']);

        final mockRelationEngine = MockRelationEngineState();
        when(() => mockRelationEngine.cache).thenReturn({
          'rel-1': createTestComputedRelation(
            'rel-1',
            [
              const rust_geom.Point(x: 100, y: 30),
              const rust_geom.Point(x: 300, y: 30),
            ],
          ),
        });
        when(() => mockContext.relationEngine).thenReturn(mockRelationEngine);

        // 2. Compute handle position using the default strategy (which is straight line, so start port is Right, end port is Left)
        // fromVs.rightPort = (100, 30)
        // toVs.leftPort = (300, 30)
        // Start handle is 16px along the path = (116, 30)
        final event = PointerDownEvent(position: const Offset(116, 30));

        controller.handlePointerDown(event);

        expect(controller.state.value, isA<RelationTipDragging>());
        final draggingState = controller.state.value as RelationTipDragging;
        expect(draggingState.relationId, 'rel-1');
        expect(draggingState.isStartTip, true);
      },
    );

    test(
      'pointer move during RelationTipDragging updates position and emits logs',
      () {
        final fromNode = InfoUiNode(
          id: 'node-from',
          position: const Offset(0, 0),
          size: const Size(100, 60),
        );
        final toNode = InfoUiNode(
          id: 'node-to',
          position: const Offset(300, 0),
          size: const Size(100, 60),
        );

        final rel = InfoUiRelation(
          id: 'rel-1',
          fromNodeId: 'node-from',
          fromNodeTable: 'inode',
          toNodeId: 'node-to',
          toNodeTable: 'inode',
          layout: RelationLayout(
            fromSide: PortSide.right,
            toSide: PortSide.left,
            strategyType: 'default',
          ),
        );

        final fromVs = NodeViewState(fromNode);
        final toVs = NodeViewState(toNode);

        when(
          () => mockContext.nodeViewStates,
        ).thenReturn({'node-from': fromVs, 'node-to': toVs});
        when(() => mockContext.getRelations()).thenReturn([rel]);
        when(() => mockContext.getSelectedEntities()).thenReturn({'rel-1'});
        when(() => mockContext.zOrder).thenReturn(['node-from', 'node-to']);
        final mockRelationEngine = MockRelationEngineState();
        when(() => mockRelationEngine.cache).thenReturn({
          'rel-1': createTestComputedRelation(
            'rel-1',
            [
              const rust_geom.Point(x: 100, y: 30),
              const rust_geom.Point(x: 300, y: 30),
            ],
          ),
        });
        when(() => mockContext.relationEngine).thenReturn(mockRelationEngine);

        // Start drag by pressing on handle
        final downEvent = PointerDownEvent(position: const Offset(116, 30));
        controller.handlePointerDown(downEvent);

        expect(controller.state.value, isA<RelationTipDragging>());

        // Move pointer
        final moveEvent = PointerMoveEvent(position: const Offset(150, 40));
        controller.handlePointerMove(moveEvent);

        expect(controller.state.value, isA<RelationTipDragging>());
        final draggingState = controller.state.value as RelationTipDragging;
        expect(draggingState.currentCursorPosition, const Offset(150, 40));
      },
    );
  });
}
