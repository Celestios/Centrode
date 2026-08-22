import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/ui/canvas/layers/relation_layer.dart';
import 'package:centrode/features/graph/ui/canvas/painters/relation_painter.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'package:centrode/features/graph/presentation/theme_manager.dart';
import 'dart:typed_data';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:centrode/src/rust/domain/routing.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockCommandQueueProcessor extends Mock implements CommandQueueProcessor {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockThemeController extends Mock implements ThemeController {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockInteractionController extends Mock implements InteractionController {}

ComputedRelation createTestComputedRelation(
  RawUuid idStr,
  List<Point> pathPoints,
) {
  return ComputedRelation(
    id: parseTypedRecordId('IRelation', idStr),
    pathPoints: pathPoints,
    pathType: PathType.straight,
    startTangent: const Point(x: 0, y: 0),
    endTangent: const Point(x: 0, y: 0),
    bodyWidths: Float64List(0),
    bodyType: BodyType.uniform,
    startEndpoint: EndpointShape.none,
    endEndpoint: EndpointShape.none,
    startDirection: 0.0,
    endDirection: 0.0,
    labelPosition: const Point(x: 0, y: 0),
    labelAnchor: LabelAnchor.center,
    hitTestPoints: pathPoints,
    dependsOnNodes: const [],
    bbox: const rust_geom.Rect(x: 0, y: 0, width: 0, height: 0),
    startMargin: 0.0,
    endMargin: 0.0,
    startArrowCenter: const Point(x: 0, y: 0),
    endArrowCenter: const Point(x: 0, y: 0),
    startPoint: pathPoints.isNotEmpty
        ? pathPoints.first
        : const Point(x: 0, y: 0),
    endPoint: pathPoints.isNotEmpty
        ? pathPoints.last
        : const Point(x: 0, y: 0),
    startHandlePos: pathPoints.isNotEmpty
        ? Point(x: pathPoints.first.x + 16, y: pathPoints.first.y)
        : const Point(x: 0, y: 0),
    endHandlePos: pathPoints.length >= 2
        ? Point(x: pathPoints.last.x - 16, y: pathPoints.last.y)
        : const Point(x: 0, y: 0),
    controlPoints: const [],
    knots: Float64List(0),
    nudgeColors: const [],
    composeActive: false,
    startShapePath: const [],
    endShapePath: const [],
    startShapeFilled: false,
    endShapeFilled: false,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Rect.zero);
  });

  testWidgets(
    'RelationLayer correctly rebuilds and propagates dragging overrides',
    (WidgetTester tester) async {
      final mockQueryController = MockGraphDataQueryController();
      final mockCommandProcessor = MockCommandQueueProcessor();
      final mockTheme = MockThemeController();

      final fromNode = InfoUiNode(
        id: RawUuid.fromString('node-from'),
        position: const Offset(10, 10),
        size: const Size(100, 50),
      );
      final toNode = InfoUiNode(
        id: RawUuid.fromString('node-to'),
        position: const Offset(210, 10),
        size: const Size(100, 50),
      );

      final rel = InfoUiRelation(
        id: RawUuid.fromString('rel-1'),
        fromNodeId: RawUuid.fromString('node-from'),
        fromNodeTable: 'inode',
        toNodeId: RawUuid.fromString('node-to'),
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

      when(() => mockQueryController.relations).thenReturn([rel]);
      when(() => mockQueryController.nodeLookup).thenReturn({
        RawUuid.fromString('node-from'): fromNode,
        RawUuid.fromString('node-to'): toNode,
      });
      when(
        () => mockQueryController.relationLookup,
      ).thenReturn({RawUuid.fromString('rel-1'): rel});
      when(
        () => mockQueryController.onEntityUpdate,
      ).thenAnswer((_) => const Stream.empty());

      final mockRelationEngine = MockRelationEngineState();
      final testComputed = createTestComputedRelation(
        RawUuid.fromString('rel-1'),
        [
          const Point(x: 110, y: 35),
          const Point(x: 210, y: 35),
        ],
      );
      when(
        () => mockRelationEngine.cache,
      ).thenReturn({RawUuid.fromString('rel-1'): testComputed});
      when(
        () => mockRelationEngine.previewCache,
      ).thenReturn({});
      when(
        () => mockRelationEngine.cacheNotifier,
      ).thenReturn(ValueNotifier<int>(0));
      when(
        () => mockQueryController.relationEngine,
      ).thenReturn(mockRelationEngine);

      when(
        () => mockTheme.currentGraphTheme,
      ).thenReturn(const GraphTheme(id: 'test', name: 'test'));
      when(() => mockTheme.addListener(any())).thenAnswer((_) {});
      when(() => mockTheme.removeListener(any())).thenAnswer((_) {});

      final renderState = NodeRenderState(
        mockQueryController,
        mockCommandProcessor,
      );
      renderState.viewStates[RawUuid.fromString('node-from')] = fromVs;
      renderState.viewStates[RawUuid.fromString('node-to')] = toVs;
      renderState.selectedEntities.add(RawUuid.fromString('rel-1'));

      final mockInteraction = MockInteractionController();
      final stateNotifier = ValueNotifier<CanvasInteractionState>(
        RelationTipDragging(
          relationId: RawUuid.fromString('rel-1'),
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
              InheritedProvider<GraphDataQueryController>.value(
                value: mockQueryController,
              ),
              InheritedProvider<CommandQueueProcessor>.value(
                value: mockCommandProcessor,
              ),
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
        relationId: RawUuid.fromString('rel-1'),
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
      expect(dto.id, RawUuid.fromString('rel-1'));
      expect(dto.startPoint, const Offset(150, 40));
    },
  );

  testWidgets(
    'Gesture dragging relation handle propagates pointer move updates to RelationPainter in real time',
    (WidgetTester tester) async {
      final mockQueryController = MockGraphDataQueryController();
      final mockCommandProcessor = MockCommandQueueProcessor();
      final mockTheme = MockThemeController();

      final fromNode = InfoUiNode(
        id: RawUuid.fromString('node-from'),
        position: const Offset(10, 10),
        size: const Size(100, 50),
      );
      final toNode = InfoUiNode(
        id: RawUuid.fromString('node-to'),
        position: const Offset(210, 10),
        size: const Size(100, 50),
      );

      final rel = InfoUiRelation(
        id: RawUuid.fromString('rel-1'),
        fromNodeId: RawUuid.fromString('node-from'),
        fromNodeTable: 'inode',
        toNodeId: RawUuid.fromString('node-to'),
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

      when(() => mockQueryController.relations).thenReturn([rel]);
      when(() => mockQueryController.nodeLookup).thenReturn({
        RawUuid.fromString('node-from'): fromNode,
        RawUuid.fromString('node-to'): toNode,
      });
      when(
        () => mockQueryController.relationLookup,
      ).thenReturn({RawUuid.fromString('rel-1'): rel});
      when(
        () => mockQueryController.onEntityUpdate,
      ).thenAnswer((_) => const Stream.empty());

      final mockRelationEngine = MockRelationEngineState();
      when(() => mockRelationEngine.cache).thenReturn({
        RawUuid.fromString('rel-1'): createTestComputedRelation(
          RawUuid.fromString('rel-1'),
          [
            const Point(x: 110, y: 35),
            const Point(x: 210, y: 35),
          ],
        ),
      });
      when(
        () => mockRelationEngine.cacheNotifier,
      ).thenReturn(ValueNotifier<int>(0));
      when(
        () => mockRelationEngine.previewCache,
      ).thenReturn({});
      when(
        () => mockQueryController.relationEngine,
      ).thenReturn(mockRelationEngine);

      final mockSpatial = MockSpatialHashGrid();
      when(() => mockQueryController.spatialGrid).thenReturn(mockSpatial);
      when(
        () => mockQueryController.canvasBounds,
      ).thenReturn(BoundingBox(minX: 0, minY: 0, maxX: 100, maxY: 100));
      when(() => mockSpatial.queryRect(any())).thenReturn(<RawUuid>{});

      when(
        () => mockTheme.currentGraphTheme,
      ).thenReturn(const GraphTheme(id: 'test', name: 'test'));
      when(() => mockTheme.addListener(any())).thenAnswer((_) {});
      when(() => mockTheme.removeListener(any())).thenAnswer((_) {});

      final renderState = NodeRenderState(
        mockQueryController,
        mockCommandProcessor,
      );
      renderState.viewStates[RawUuid.fromString('node-from')] = fromVs;
      renderState.viewStates[RawUuid.fromString('node-to')] = toVs;
      renderState.selectedEntities.add(RawUuid.fromString('rel-1'));

      final transformController = TransformationController();
      final viewportController = ViewportController(mockQueryController);
      final environment = CanvasInteractionEnvironment(
        queryController: mockQueryController,
        commandProcessor: mockCommandProcessor,
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
              InheritedProvider<GraphDataQueryController>.value(
                value: mockQueryController,
              ),
              InheritedProvider<CommandQueueProcessor>.value(
                value: mockCommandProcessor,
              ),
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
      expect(dto.id, RawUuid.fromString('rel-1'));
      expect(dto.startPoint, const Offset(150, 40));

      await gesture.up();
      await tester.pump();
    },
  );
}
