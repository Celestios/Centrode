import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/ui/canvas/layers/relation_layer.dart';
import 'package:mycelium/features/graph/ui/canvas/painters/relation_painter.dart';
import 'package:mycelium/features/graph/engine/base_interaction_state.dart';
import 'package:mycelium/features/graph/engine/interaction_engine.dart';
import 'package:mycelium/features/graph/engine/interaction_facade.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/features/graph/store/spatial_index.dart';
import 'package:mycelium/features/graph/store/relation_engine_state.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'dart:typed_data';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart';
import 'package:mycelium/src/rust/domain/relation_engine/geometry.dart' as rust_geom;
import 'package:mycelium/src/rust/domain/styles.dart';

class MockGraphDataController extends Mock implements GraphDataController {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockThemeController extends Mock implements ThemeController {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockInteractionController extends Mock implements InteractionController {}

ComputedRelation createTestComputedRelation(String id, List<rust_geom.Point> pathPoints) {
  return ComputedRelation(
    id: id,
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
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Rect.zero);
  });

  testWidgets(
    'RelationLayer correctly rebuilds and propagates dragging overrides',
    (WidgetTester tester) async {
      final mockController = MockGraphDataController();
      final mockTheme = MockThemeController();

      final fromNode = InfoUiNode(
        id: 'node-from',
        position: const Offset(10, 10),
        size: const Size(100, 50),
      );
      final toNode = InfoUiNode(
        id: 'node-to',
        position: const Offset(210, 10),
        size: const Size(100, 50),
      );

      final rel = InfoUiRelation(
        id: 'rel-1',
        fromNodeId: 'node-from',
        fromNodeTable: 'inode',
        toNodeId: 'node-to',
        toNodeTable: 'inode',
        layout: const RelationLayout(
          fromSide: null,
          toSide: null,
          strategyType: 'default',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);

      fromVs.sizeNotifier.value = const Size(100, 50);
      toVs.sizeNotifier.value = const Size(100, 50);

      when(() => mockController.relations).thenReturn([rel]);
      when(
        () => mockController.nodeLookup,
      ).thenReturn({'node-from': fromNode, 'node-to': toNode});
      when(() => mockController.relationLookup).thenReturn({'rel-1': rel});
      when(
        () => mockController.onEntityUpdate,
      ).thenAnswer((_) => const Stream.empty());

      final mockRelationEngine = MockRelationEngineState();
      final testComputed = createTestComputedRelation(
        'rel-1',
        [
          const rust_geom.Point(x: 110, y: 35),
          const rust_geom.Point(x: 210, y: 35),
        ],
      );
      when(() => mockRelationEngine.cache).thenReturn({'rel-1': testComputed});
      when(() => mockRelationEngine.cacheNotifier)
          .thenReturn(ValueNotifier<int>(0));
      when(() => mockController.relationEngine)
          .thenReturn(mockRelationEngine);

      when(
        () => mockTheme.currentGraphTheme,
      ).thenReturn(const GraphTheme(id: 'test', name: 'test'));
      when(() => mockTheme.addListener(any())).thenAnswer((_) {});
      when(() => mockTheme.removeListener(any())).thenAnswer((_) {});

      final renderState = NodeRenderState(mockController, mockController);
      renderState.viewStates['node-from'] = fromVs;
      renderState.viewStates['node-to'] = toVs;
      renderState.selectedEntities.add('rel-1');

      final mockInteraction = MockInteractionController();
      final stateNotifier = ValueNotifier<CanvasInteractionState>(
        RelationTipDragging(
          relationId: 'rel-1',
          isStartTip: true,
          originalPosition: const Offset(110, 35),
          currentCursorPosition: const Offset(110, 35),
        ),
      );
      final cursorNotifier = ValueNotifier<MouseCursor>(
        SystemMouseCursors.grab,
      );
      final panScaleNotifier = ValueNotifier<bool>(false);

      when(() => mockInteraction.state).thenReturn(stateNotifier);
      when(() => mockInteraction.cursor).thenReturn(cursorNotifier);
      when(() => mockInteraction.panScaleEnabled).thenReturn(panScaleNotifier);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              InheritedProvider<GraphDataController>.value(value: mockController),
              ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
              ChangeNotifierProvider<ThemeController>.value(value: mockTheme),
              Provider<InteractionController>.value(value: mockInteraction),
            ],
            child: Scaffold(
              body: SizedBox(
                width: 500,
                height: 500,
                child: Stack(children: [RelationLayer()]),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Now update state (simulate pointer move event)
      stateNotifier.value = RelationTipDragging(
        relationId: 'rel-1',
        isStartTip: true,
        originalPosition: const Offset(110, 35),
        currentCursorPosition: const Offset(150, 40), // Moved by 40px
      );

      await tester.pump();

      // Verify painter overrides
      final customPaintFinder = find.byType(CustomPaint);
      final customPaint = tester
          .widgetList<CustomPaint>(customPaintFinder)
          .firstWhere((w) => w.painter is RelationPainter);
      final painter = customPaint.painter as RelationPainter;
      expect(painter.paintDtos, hasLength(1));
      final dto = painter.paintDtos.first;
      expect(dto.id, 'rel-1');
      expect(dto.startPoint, const Offset(150, 40));
    },
  );

  testWidgets(
    'Gesture dragging relation handle propagates pointer move updates to RelationPainter in real time',
    (WidgetTester tester) async {
      final mockController = MockGraphDataController();
      final mockTheme = MockThemeController();

      final fromNode = InfoUiNode(
        id: 'node-from',
        position: const Offset(10, 10),
        size: const Size(100, 50),
      );
      final toNode = InfoUiNode(
        id: 'node-to',
        position: const Offset(210, 10),
        size: const Size(100, 50),
      );

      final rel = InfoUiRelation(
        id: 'rel-1',
        fromNodeId: 'node-from',
        fromNodeTable: 'inode',
        toNodeId: 'node-to',
        toNodeTable: 'inode',
        layout: const RelationLayout(
          fromSide: null,
          toSide: null,
          strategyType: 'default',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);

      fromVs.sizeNotifier.value = const Size(100, 50);
      toVs.sizeNotifier.value = const Size(100, 50);

      when(() => mockController.relations).thenReturn([rel]);
      when(
        () => mockController.nodeLookup,
      ).thenReturn({'node-from': fromNode, 'node-to': toNode});
      when(() => mockController.relationLookup).thenReturn({'rel-1': rel});
      when(
        () => mockController.onEntityUpdate,
      ).thenAnswer((_) => const Stream.empty());

      final mockRelationEngine = MockRelationEngineState();
      when(() => mockRelationEngine.cache).thenReturn({
        'rel-1': createTestComputedRelation(
          'rel-1',
          [
            const rust_geom.Point(x: 110, y: 35),
            const rust_geom.Point(x: 210, y: 35),
          ],
        ),
      });
      when(() => mockRelationEngine.cacheNotifier)
          .thenReturn(ValueNotifier<int>(0));
      when(() => mockController.relationEngine)
          .thenReturn(mockRelationEngine);

      final mockSpatial = MockSpatialHashGrid();
      when(() => mockController.spatialGrid).thenReturn(mockSpatial);
      when(() => mockController.canvasBounds).thenReturn(
        BoundingBox(minX: 0, minY: 0, maxX: 100, maxY: 100),
      );
      when(() => mockSpatial.queryRect(any())).thenReturn(<String>{});

      when(
        () => mockTheme.currentGraphTheme,
      ).thenReturn(const GraphTheme(id: 'test', name: 'test'));
      when(() => mockTheme.addListener(any())).thenAnswer((_) {});
      when(() => mockTheme.removeListener(any())).thenAnswer((_) {});

      final renderState = NodeRenderState(mockController, mockController);
      renderState.viewStates['node-from'] = fromVs;
      renderState.viewStates['node-to'] = toVs;
      renderState.selectedEntities.add('rel-1');

      final transformController = TransformationController();
      final viewportController = ViewportController(mockController);
      final environment = CanvasInteractionEnvironment(
        dataController: mockController,
        renderState: renderState,
        viewportController: viewportController,
        getScale: () => 1.0,
      );
      final interactionController = InteractionController(
        transformController: transformController,
        environment: environment,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              InheritedProvider<GraphDataController>.value(value: mockController),
              ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
              ChangeNotifierProvider<ThemeController>.value(value: mockTheme),
              Provider<InteractionController>.value(
                value: interactionController,
              ),
            ],
            child: Scaffold(
              body: SizedBox(
                width: 500,
                height: 500,
                child: ValueListenableBuilder<CanvasInteractionState>(
                  valueListenable: interactionController.state,
                  builder: (context, state, _) {
                    return Listener(
                      onPointerDown: interactionController.handlePointerDown,
                      onPointerMove: interactionController.handlePointerMove,
                      onPointerUp: interactionController.handlePointerUp,
                      child: Stack(children: [RelationLayer()]),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify initial handle position and click on it.
      // The handle is around (126, 35). Let's click at (126, 35) to start drag.
      final gesture = await tester.startGesture(const Offset(126, 35));
      await tester.pump();

      expect(interactionController.state.value, isA<RelationTipDragging>());

      // Move to (150, 40)
      await gesture.moveTo(const Offset(150, 40));
      await tester.pump();

      // Check if RelationPainter got the new overrides
      final customPaintFinder = find.byType(CustomPaint);
      final customPaint = tester
          .widgetList<CustomPaint>(customPaintFinder)
          .firstWhere((w) => w.painter is RelationPainter);
      final painter = customPaint.painter as RelationPainter;
      expect(painter.paintDtos, hasLength(1));
      final dto = painter.paintDtos.first;
      expect(dto.id, 'rel-1');
      expect(dto.startPoint, const Offset(150, 40));

      await gesture.up();
      await tester.pump();
    },
  );
}
