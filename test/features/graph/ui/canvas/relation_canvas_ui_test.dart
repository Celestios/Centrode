import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/hit_test_resolver.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/ui/canvas/context_toolbar_overlay.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/vertical_context_toolbar.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/routing.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;

class MockInteractionContext extends Mock implements InteractionContext {}
class MockRelationEngineState extends Mock implements RelationEngineState {}
class MockNodeViewState extends Mock implements NodeViewState {}
class MockWorkspaceTabsController extends Mock implements WorkspaceTabsController {}
class MockTabSession extends Mock implements TabSession {}

void main() {
  group('Relation Canvas UI: Label Display Mode', () {
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
      when(() => mockCtx.getNode(fromId)).thenReturn(fromNode);
      when(() => mockCtx.getNode(toId)).thenReturn(toNode);
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

  group('Relation Canvas UI: Toolbar Visibility', () {
    testWidgets(
      'Floating toolbar menu disappears when relation tip is dragging and reappears on idle',
      (tester) async {
        final nodeAId = RawUuid.v4();
        final nodeBId = RawUuid.v4();
        final relId = RawUuid.v4();

        final nodeA = InfoUiNode(
          id: nodeAId,
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        final nodeB = InfoUiNode(
          id: nodeBId,
          position: const Offset(400, 100),
          size: const Size(100, 100),
        );
        final relation = InfoUiRelation(
          id: relId,
          fromNodeId: nodeAId,
          toNodeId: nodeBId,
          fromNodeTable: 'Nodes',
          toNodeTable: 'Nodes',
          verb: 'link',
        );

        final api = InMemoryGraphApi();
        final queryController = GraphDataQueryController(api);
        final processor = CommandQueueProcessor(api, queryController);
        final renderState = NodeRenderState(queryController, processor);
        final viewportController = ViewportController(queryController);
        final transformController = TransformationController();
        final interactionEnv = CanvasInteractionEnvironment(
          queryController: queryController,
          commandProcessor: processor,
          renderState: renderState,
          viewportController: viewportController,
          getScale: () => 1.0,
        );
        final interactionController = InteractionController(
          transformController: transformController,
          environment: interactionEnv,
        );

        queryController.store.nodeLookup[nodeAId] = nodeA;
        queryController.store.nodeLookup[nodeBId] = nodeB;
        queryController.store.relationLookup[relId] = relation;
        renderState.viewStates[nodeAId] = NodeViewState(nodeA);
        renderState.viewStates[nodeBId] = NodeViewState(nodeB);

        // Select the relation
        renderState.selectionState.selectEntity(relId);

        final mockTabsController = MockWorkspaceTabsController();
        final mockSession = MockTabSession();
        when(() => mockTabsController.activeSession).thenReturn(mockSession);
        when(() => mockSession.showLeftPanel).thenReturn(ValueNotifier<bool>(false));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WorkspaceTabsController>.value(
                value: mockTabsController,
              ),
              Provider<GraphDataQuery>.value(value: queryController),
              ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
              Provider<ViewportController>.value(value: viewportController),
              Provider<InteractionController>.value(value: interactionController),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    ContextToolbarOverlay(
                      renderState: renderState,
                      queryController: queryController,
                      interactionContext: interactionController.environment,
                      viewportController: viewportController,
                      interactionController: interactionController,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. In CanvasIdle state with selected relation, toolbar is visible
        expect(find.byType(VerticalContextToolbar), findsOneWidget);

        // 2. Switch to RelationTipDragging state
        interactionController.state.value = RelationTipDragging(
          relationId: relId,
          isStartTip: false,
          originalPosition: const Offset(400, 150),
          currentCursorPosition: const Offset(350, 150),
        );
        await tester.pump();

        // Floating toolbar menu should disappear!
        expect(find.byType(VerticalContextToolbar), findsNothing);

        // 3. Switch back to CanvasIdle state
        interactionController.state.value = const CanvasIdle();
        await tester.pump();

        // Floating toolbar menu reappears!
        expect(find.byType(VerticalContextToolbar), findsOneWidget);
      },
    );
  });
}
