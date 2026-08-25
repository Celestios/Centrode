import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/ui/canvas/layers/port_layer.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  testWidgets(
    'PortLayer suppresses hoveredPort highlighting during RelationDrawing on target node',
    (tester) async {
      final nodeId1 = RawUuid.v4();
      final nodeId2 = RawUuid.v4();

      final node1 = InfoUiNode(
        id: nodeId1,
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = InfoUiNode(
        id: nodeId2,
        position: const Offset(200, 0),
        size: const Size(100, 100),
      );

      final vs1 = NodeViewState(node1);
      final vs2 = NodeViewState(node2);

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

      queryController.store.nodeLookup[nodeId1] = node1;
      queryController.store.nodeLookup[nodeId2] = node2;
      renderState.viewStates[nodeId1] = vs1;
      renderState.viewStates[nodeId2] = vs2;

      interactionController.state.value =
          RelationDrawing({nodeId1}, const Offset(50, 0));

      const port = Port(
        side: PortSide.top,
        type: PortType.middle,
        index: 0,
        position: Offset(50, 0),
        edgePosition: Offset(50, 0),
      );
      renderState.hoveredPortNotifier.value = port;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GraphDataQuery>.value(value: queryController),
            ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
            Provider<ViewportController>.value(value: viewportController),
            Provider<InteractionController>.value(value: interactionController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PortLayer(),
            ),
          ),
        ),
      );

      // Hover over node 2
      renderState.hoveredNodeNotifier.value = nodeId2;
      await tester.pump();

      // Verify CustomPaint with PortPainter is built with hoveredPort: null during RelationDrawing
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PortPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final CustomPaint customPaint = tester.widget(customPaintFinder);
      final PortPainter painter = customPaint.painter as PortPainter;

      expect(painter.hoveredPort, isNull);

      // When returning to CanvasIdle, hoveredPort should be restored
      interactionController.state.value = const CanvasIdle();
      await tester.pump();

      final CustomPaint updatedCustomPaint = tester.widget(customPaintFinder);
      final PortPainter updatedPainter =
          updatedCustomPaint.painter as PortPainter;
      expect(updatedPainter.hoveredPort, equals(port));
    },
  );
}
