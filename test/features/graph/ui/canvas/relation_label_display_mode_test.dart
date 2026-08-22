import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/engine/hit_test_resolver.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:centrode/src/rust/domain/routing.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';

class MockInteractionContext extends Mock implements InteractionContext {}
class MockRelationEngineState extends Mock implements RelationEngineState {}
class MockNodeViewState extends Mock implements NodeViewState {}

void main() {
  group('Relation Label Display Mode', () {
    late MockInteractionContext mockCtx;
    late MockRelationEngineState mockEngine;
    late TabSession session;
    final hitResolver = HitTestResolver();

    final relId = RawUuid.fromString('rel-1');
    final fromId = RawUuid.fromString('node-1');
    final toId = RawUuid.fromString('node-2');

    final testRel = InfoUiRelation(
      id: relId,
      fromNodeId: fromId,
      toNodeId: toId,
      fromNodeTable: 'nodes',
      toNodeTable: 'nodes',
      verb: 'connects_to',
      direction: RelationDirection.forward,
      layer: 'default',
    );

    final mockComputed = ComputedRelation(
      id: parseTypedRecordId('IRelation', relId),
      pathPoints: const [Point(x: 100, y: 100), Point(x: 300, y: 100)],
      pathType: PathType.straight,
      startTangent: const Point(x: 1, y: 0),
      endTangent: const Point(x: 1, y: 0),
      bodyWidths: Float64List(0),
      bodyType: BodyType.uniform,
      startEndpoint: EndpointShape.none,
      endEndpoint: EndpointShape.none,
      startDirection: 0.0,
      endDirection: 0.0,
      labelPosition: const Point(x: 200, y: 100),
      labelAnchor: LabelAnchor.center,
      hitTestPoints: const [Point(x: 100, y: 100), Point(x: 300, y: 100)],
      dependsOnNodes: const [],
      bbox: const rust_geom.Rect(x: 100, y: 100, width: 200, height: 0),
      startMargin: 0.0,
      endMargin: 0.0,
      startArrowCenter: const Point(x: 100, y: 100),
      endArrowCenter: const Point(x: 300, y: 100),
      startPoint: const Point(x: 100, y: 100),
      endPoint: const Point(x: 300, y: 100),
      startHandlePos: const Point(x: 100, y: 100),
      endHandlePos: const Point(x: 300, y: 100),
      controlPoints: const [],
      knots: Float64List(0),
      nudgeColors: const [],
      composeActive: false,
      startShapePath: const [],
      endShapePath: const [],
      startShapeFilled: false,
      endShapeFilled: false,
    );

    setUp(() {
      mockCtx = MockInteractionContext();
      mockEngine = MockRelationEngineState();
      session = TabSession(
        id: 'test-session',
        storagePath: '/tmp',
        name: 'Test Session',
      );

      final fromNode = InfoUiNode(
        id: fromId,
        position: const Offset(0, 50),
        size: const Size(100, 100),
      );
      final toNode = InfoUiNode(
        id: toId,
        position: const Offset(300, 50),
        size: const Size(100, 100),
      );
      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);

      when(() => mockCtx.boundSession).thenReturn(session);
      when(() => mockCtx.activeScope).thenReturn(const RootViewportScope());
      when(() => mockCtx.relationEngine).thenReturn(mockEngine);
      when(() => mockEngine.cache).thenReturn({relId: mockComputed});
      when(() => mockCtx.getRelations()).thenReturn([testRel]);
      when(() => mockCtx.zOrder).thenReturn([]);
      when(() => mockCtx.nodeViewStates).thenReturn({
        fromId: fromVs,
        toId: toVs,
      });
      when(() => mockCtx.optArea).thenReturn(null);
    });

    tearDown(() {
      session.dispose();
    });

    test('never mode hides label hit target', () {
      session.relationLabelModeNotifier.value = 'never';
      when(() => mockCtx.getSelectedEntities()).thenReturn({});

      // Point in label box off line (200, 115) -> returns none because label box is disabled
      final result = hitResolver.resolve(const Offset(200, 115), mockCtx, false);
      expect(result.type, equals(HitTestType.none));
    });

    test('always mode shows label hit target even when not selected', () {
      session.relationLabelModeNotifier.value = 'always';
      when(() => mockCtx.getSelectedEntities()).thenReturn({});

      // Point inside label box (200, 115) -> returns relationLabel
      final result = hitResolver.resolve(const Offset(200, 115), mockCtx, false);
      expect(result.type, equals(HitTestType.relationLabel));
    });

    test('auto mode shows label hit target only when selected', () {
      session.relationLabelModeNotifier.value = 'auto';

      // Unselected -> label box at (200, 115) is not hit
      when(() => mockCtx.getSelectedEntities()).thenReturn({});
      final unselectedResult = hitResolver.resolve(const Offset(200, 115), mockCtx, false);
      expect(unselectedResult.type, equals(HitTestType.none));

      // Selected -> label box at (200, 115) is hit
      when(() => mockCtx.getSelectedEntities()).thenReturn({relId});
      final selectedResult = hitResolver.resolve(const Offset(200, 115), mockCtx, false);
      expect(selectedResult.type, equals(HitTestType.relationLabel));
    });
  });
}
