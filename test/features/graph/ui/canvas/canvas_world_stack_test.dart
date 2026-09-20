import 'dart:collection' show UnmodifiableMapView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:centrode/features/graph/ui/canvas/canvas_world_stack.dart';
import 'package:centrode/features/graph/ui/canvas/layers/grid_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/relation_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/node_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/overlay_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/port_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/active_drawing_layer.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/drawing_interceptor.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/models/models.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockGraphDataCommand extends Mock implements GraphDataCommand {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockHierarchicalSpatialIndex extends Mock
    implements HierarchicalSpatialIndex {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockInteractionController extends Mock implements InteractionController {}

class MockDrawingGestureInterceptor extends Mock
    implements DrawingGestureInterceptor {}

class MockTabSession extends Mock implements TabSession {}

class MockWorkspaceTabsController extends Mock
    implements WorkspaceTabsController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RootViewportScope());
  });

  late MockGraphDataQueryController mockQuery;
  late MockGraphDataCommand mockCommand;
  late MockSpatialHashGrid mockSpatial;
  late MockHierarchicalSpatialIndex mockSpatialIndex;
  late MockRelationEngineState mockRelationEngine;
  late MockInteractionController mockInteraction;
  late MockDrawingGestureInterceptor mockDrawing;
  late MockTabSession mockSession;
  late MockWorkspaceTabsController mockTabsController;
  late NodeRenderState renderState;
  late ViewportController viewportController;

  late ValueNotifier<List<Offset>> activeStrokeNotifier;
  late ValueNotifier<String> brushColorNotifier;
  late ValueNotifier<double> brushThicknessNotifier;
  late ValueNotifier<String> brushTypeNotifier;
  late ValueNotifier<Offset?> mousePosNotifier;
  late ValueNotifier<Offset> elasticOverscrollNotifier;
  late ValueNotifier<MouseCursor> cursorNotifier;

  setUp(() {
    mockQuery = MockGraphDataQueryController();
    mockCommand = MockGraphDataCommand();
    mockSpatial = MockSpatialHashGrid();
    mockSpatialIndex = MockHierarchicalSpatialIndex();
    mockRelationEngine = MockRelationEngineState();
    mockInteraction = MockInteractionController();
    mockDrawing = MockDrawingGestureInterceptor();
    mockSession = MockTabSession();
    mockTabsController = MockWorkspaceTabsController();

    activeStrokeNotifier = ValueNotifier<List<Offset>>([]);
    brushColorNotifier = ValueNotifier<String>('#00E5FF');
    brushThicknessNotifier = ValueNotifier<double>(4.0);
    brushTypeNotifier = ValueNotifier<String>('pen');
    mousePosNotifier = ValueNotifier<Offset?>(null);
    elasticOverscrollNotifier = ValueNotifier<Offset>(Offset.zero);
    cursorNotifier = ValueNotifier<MouseCursor>(SystemMouseCursors.basic);

    when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
    when(() => mockQuery.spatialIndex).thenReturn(mockSpatialIndex);
    when(() => mockQuery.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationsInScope(any())).thenReturn(const []);
    when(() => mockQuery.relations).thenReturn(const []);
    when(
      () => mockQuery.optAreaNotifier,
    ).thenReturn(ValueNotifier<Rect?>(null));
    when(
      () => mockQuery.canvasBounds,
    ).thenReturn(BoundingBox(minX: 0, minY: 0, maxX: 1000, maxY: 1000));
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockQuery.relationEngine).thenReturn(mockRelationEngine);
    when(
      () => mockRelationEngine.cacheNotifier,
    ).thenReturn(ValueNotifier<int>(0));

    when(() => mockDrawing.activeStroke).thenReturn(activeStrokeNotifier);
    when(() => mockSession.brushColorNotifier).thenReturn(brushColorNotifier);
    when(
      () => mockSession.brushThicknessNotifier,
    ).thenReturn(brushThicknessNotifier);
    when(() => mockSession.brushTypeNotifier).thenReturn(brushTypeNotifier);
    when(
      () => mockSession.toolModeNotifier,
    ).thenReturn(ValueNotifier('select'));
    when(
      () => mockSession.relationLabelModeNotifier,
    ).thenReturn(ValueNotifier('auto'));
    when(() => mockTabsController.activeSession).thenReturn(mockSession);
    when(() => mockInteraction.cursor).thenReturn(cursorNotifier);
    when(
      () => mockInteraction.state,
    ).thenReturn(ValueNotifier(const CanvasIdle()));

    renderState = NodeRenderState(mockQuery, mockCommand);
    viewportController = ViewportController(mockQuery);
  });

  tearDown(() {
    viewportController.dispose();
    renderState.dispose();
    activeStrokeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
    mousePosNotifier.dispose();
    elasticOverscrollNotifier.dispose();
    cursorNotifier.dispose();
  });

  group('CanvasWorldStack Tests', () {
    testWidgets(
      'Mounts all 6 layers inside UnboundedStack with Clip.none in correct order',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<GraphDataQuery>.value(value: mockQuery),
              ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
              Provider<InteractionController>.value(value: mockInteraction),
              Provider<ViewportController>.value(value: viewportController),
              ChangeNotifierProvider<WorkspaceTabsController>.value(
                value: mockTabsController,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CanvasWorldStack(
                  viewportStateNotifier:
                      viewportController.viewportStateNotifier,
                  mousePositionNotifier: mousePosNotifier,
                  elasticOverscrollNotifier: elasticOverscrollNotifier,
                  drawingInterceptor: mockDrawing,
                  session: mockSession,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        final stackFinder = find
            .descendant(
              of: find.byType(CanvasWorldStack),
              matching: find.byType(UnboundedStack),
            )
            .first;

        expect(stackFinder, findsOneWidget);
        final unboundedStack = tester.widget<UnboundedStack>(stackFinder);
        expect(unboundedStack.clipBehavior, Clip.none);

        expect(find.byType(GridLayer), findsOneWidget);
        expect(find.byType(RelationLayer), findsOneWidget);
        expect(find.byType(NodeLayer), findsOneWidget);
        expect(find.byType(OverlayLayer), findsOneWidget);
        expect(find.byType(PortLayer), findsOneWidget);
        expect(find.byType(ActiveDrawingLayer), findsOneWidget);

        final children = unboundedStack.children;
        expect(children.length, 6);
        expect(children[0], isA<ValueListenableBuilder<ViewportStateGrid>>());
        expect(children[1], isA<RelationLayer>());
        expect(children[2], isA<NodeLayer>());
        expect(children[3], isA<OverlayLayer>());
        expect(children[4], isA<PortLayer>());
        expect(children[5], isA<ActiveDrawingLayer>());
      },
    );
  });
}
