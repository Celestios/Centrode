import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/ui/canvas/context_toolbar_overlay.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/vertical_context_toolbar.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockWorkspaceTabsController extends Mock
    implements WorkspaceTabsController {}

class MockTabSession extends Mock implements TabSession {}

void main() {
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
}
