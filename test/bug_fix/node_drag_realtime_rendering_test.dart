import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/style_manager.dart';
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'package:centrode/features/graph/ui/canvas/layers/node_layer.dart';

void main() {
  testWidgets('NodeLayer CustomPaint responds to positionNotifier during dragging', (tester) async {
    final api = InMemoryGraphApi();
    final queryController = GraphDataQueryController(api);
    final processor = CommandQueueProcessor(api, queryController);
    final renderState = NodeRenderState(queryController, processor);
    final viewportController = ViewportController(queryController);

    final styleManager = StyleManager(queryController.store);
    styleManager.setTheme(
      const GraphTheme(
        id: 'test',
        name: 'test',
        primaryColor: Color(0xFF123456),
        fontFamily: 'Roboto',
        bodyFontSize: 14.0,
        borderRadius: 8.0,
      ),
    );

    final nodeId = processor.nodeMutations.createNode(
      UiNodes.info,
      const Offset(100, 100),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GraphDataQuery>.value(value: queryController),
          ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
          Provider<ViewportController>.value(value: viewportController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeLayer(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final vs = renderState.viewStates[nodeId];
    expect(vs, isNotNull);
    expect(vs!.positionNotifier.value, equals(const Offset(100, 100)));

    final customPaintFinder = find.byType(CustomPaint);
    expect(customPaintFinder, findsWidgets);

    // Get the RenderCustomPaint render object
    final elements = find.byType(CustomPaint).evaluate();
    RenderCustomPaint? nodeLayerCustomPaint;
    for (final el in elements) {
      final ro = el.renderObject;
      if (ro is RenderCustomPaint && ro.painter != null) {
        if (ro.painter.runtimeType.toString().contains('CanvasNodesPainter')) {
          nodeLayerCustomPaint = ro;
          break;
        }
      }
    }

    expect(nodeLayerCustomPaint, isNotNull);

    // Simulate drag movement on positionNotifier
    vs.positionNotifier.value = const Offset(150, 150);

    // In Flutter, when positionNotifier updates, the RenderCustomPaint MUST be marked dirty (needs paint)
    expect(nodeLayerCustomPaint!.debugNeedsPaint, isTrue);

    await tester.pump();
    expect(vs.positionNotifier.value, equals(const Offset(150, 150)));
  });
}
