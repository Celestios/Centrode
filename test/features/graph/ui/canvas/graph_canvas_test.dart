import 'dart:collection' show UnmodifiableMapView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:centrode/features/graph/ui/canvas/graph_canvas.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_stage_scope.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_gesture_router.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_camera_host.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_world_stack.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_overlay_layout.dart';
import 'package:centrode/features/graph/ui/canvas/canvas_template_drop_target.dart';
import 'package:centrode/features/graph/ui/canvas/layers/grid_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/relation_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/node_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/overlay_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/port_layer.dart';
import 'package:centrode/features/graph/ui/canvas/layers/active_drawing_layer.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/handlers/template_command_handler.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/presentation/editor_state.dart';
import 'package:centrode/features/graph/presentation/selection_state.dart';
import 'package:centrode/features/graph/presentation/drag_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/shared/copy_buffer.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockCommandQueueProcessor extends Mock implements CommandQueueProcessor {}

class MockTemplateCommandHandler extends Mock
    implements TemplateCommandHandler {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockNodeRenderState extends Mock implements NodeRenderState {}

class MockWorkspaceTabsController extends Mock
    implements WorkspaceTabsController {}

class MockTabSession extends Mock implements TabSession {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(ThemeData.dark());
    registerFallbackValue(const RootViewportScope());
  });

  late MockGraphDataQueryController mockQuery;
  late MockCommandQueueProcessor mockCommand;
  late MockTemplateCommandHandler mockTemplateHandler;
  late MockRelationEngineState mockRelationEngine;
  late MockNodeRenderState mockRenderState;
  late MockWorkspaceTabsController mockTabsController;
  late MockTabSession mockSession;
  late CopyBuffer copyBuffer;
  late HierarchicalSpatialIndex spatialIndex;

  late ValueNotifier<bool> isInitializedNotifier;
  late ValueNotifier<String> toolModeNotifier;
  late ValueNotifier<String> currentViewNotifier;
  late ValueNotifier<String> relationLabelModeNotifier;
  late ValueNotifier<String> brushColorNotifier;
  late ValueNotifier<double> brushThicknessNotifier;
  late ValueNotifier<String> brushTypeNotifier;
  late ValueNotifier<bool> showLeftPanelNotifier;
  late ValueNotifier<bool> showRightPanelNotifier;
  late ValueNotifier<bool> showBottomPanelNotifier;
  late ValueNotifier<LeftPanelType> activeLeftPanelNotifier;
  late ValueNotifier<InspectorTab> activeInspectorTabNotifier;
  late ValueNotifier<RawUuid?> activeEditIdNotifier;
  late ValueNotifier<Offset> toolbarOffsetNotifier;
  late ValueNotifier<Offset> multiToolbarOffsetNotifier;

  setUp(() {
    mockQuery = MockGraphDataQueryController();
    mockCommand = MockCommandQueueProcessor();
    mockTemplateHandler = MockTemplateCommandHandler();
    mockRelationEngine = MockRelationEngineState();
    mockRenderState = MockNodeRenderState();
    mockTabsController = MockWorkspaceTabsController();
    mockSession = MockTabSession();
    copyBuffer = CopyBuffer();
    spatialIndex = HierarchicalSpatialIndex();

    isInitializedNotifier = ValueNotifier<bool>(true);
    toolModeNotifier = ValueNotifier<String>('select');
    currentViewNotifier = ValueNotifier<String>('canvas');
    relationLabelModeNotifier = ValueNotifier<String>('auto');
    brushColorNotifier = ValueNotifier<String>('#00E5FF');
    brushThicknessNotifier = ValueNotifier<double>(4.0);
    brushTypeNotifier = ValueNotifier<String>('pen');
    showLeftPanelNotifier = ValueNotifier<bool>(true);
    showRightPanelNotifier = ValueNotifier<bool>(true);
    showBottomPanelNotifier = ValueNotifier<bool>(false);
    activeLeftPanelNotifier = ValueNotifier<LeftPanelType>(LeftPanelType.none);
    activeInspectorTabNotifier = ValueNotifier<InspectorTab>(
      InspectorTab.appearance,
    );
    activeEditIdNotifier = ValueNotifier<RawUuid?>(null);
    toolbarOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
    multiToolbarOffsetNotifier = ValueNotifier<Offset>(Offset.zero);

    // Command Processor
    when(() => mockCommand.templateMutations).thenReturn(mockTemplateHandler);

    // Query Controller
    when(() => mockQuery.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relations).thenReturn([]);
    when(() => mockQuery.relationsInScope(any())).thenReturn([]);
    when(() => mockQuery.isLoading).thenReturn(false);
    when(() => mockQuery.isLoadingNotifier).thenReturn(ValueNotifier(false));
    when(() => mockQuery.errorMessage).thenReturn(null);
    when(
      () => mockQuery.canvasBounds,
    ).thenReturn(BoundingBox(minX: 0, minY: 0, maxX: 1000, maxY: 1000));
    when(() => mockQuery.spatialIndex).thenReturn(spatialIndex);
    when(() => mockQuery.spatialGrid).thenReturn(spatialIndex.rootGrid);
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockQuery.relationEngine).thenReturn(mockRelationEngine);
    when(() => mockRelationEngine.cacheNotifier).thenReturn(ValueNotifier(0));

    // Tab Session
    when(() => mockSession.id).thenReturn('test-session');
    when(() => mockSession.name).thenReturn('Test Session');
    when(() => mockSession.storagePath).thenReturn('');
    when(() => mockSession.isInitialized).thenReturn(isInitializedNotifier);
    when(() => mockSession.toolModeNotifier).thenReturn(toolModeNotifier);
    when(() => mockSession.currentViewNotifier).thenReturn(currentViewNotifier);
    when(
      () => mockSession.relationLabelModeNotifier,
    ).thenReturn(relationLabelModeNotifier);
    when(() => mockSession.brushColorNotifier).thenReturn(brushColorNotifier);
    when(
      () => mockSession.brushThicknessNotifier,
    ).thenReturn(brushThicknessNotifier);
    when(() => mockSession.brushTypeNotifier).thenReturn(brushTypeNotifier);
    when(() => mockSession.showLeftPanel).thenReturn(showLeftPanelNotifier);
    when(() => mockSession.showRightPanel).thenReturn(showRightPanelNotifier);
    when(() => mockSession.showBottomPanel).thenReturn(showBottomPanelNotifier);
    when(() => mockSession.canUndo).thenReturn(false);
    when(() => mockSession.canRedo).thenReturn(false);
    when(() => mockSession.saveViewportState()).thenAnswer((_) async {});
    when(() => mockSession.addListener(any())).thenAnswer((_) {});
    when(() => mockSession.removeListener(any())).thenAnswer((_) {});

    // Workspace Tabs Controller
    when(() => mockTabsController.tabs).thenReturn([mockSession]);
    when(() => mockTabsController.activeIndex).thenReturn(0);
    when(() => mockTabsController.activeSession).thenReturn(mockSession);
    when(() => mockTabsController.addListener(any())).thenAnswer((_) {});
    when(() => mockTabsController.removeListener(any())).thenAnswer((_) {});

    // Render State
    final selectionState = SelectionState(mockQuery, mockCommand);
    final editorState = EditorState(mockQuery, {});
    final dragState = DragState();
    when(() => mockRenderState.selectionState).thenReturn(selectionState);
    when(() => mockRenderState.editorState).thenReturn(editorState);
    when(() => mockRenderState.dragState).thenReturn(dragState);
    when(() => mockRenderState.relationEngine).thenReturn(mockRelationEngine);
    when(() => mockRenderState.optAreaNotifier).thenReturn(ValueNotifier(null));
    when(() => mockRenderState.relationsInScope(any())).thenReturn([]);
    when(
      () => mockRenderState.activeLeftPanelNotifier,
    ).thenReturn(activeLeftPanelNotifier);
    when(
      () => mockRenderState.activeInspectorTabNotifier,
    ).thenReturn(activeInspectorTabNotifier);
    when(
      () => mockRenderState.hoveredNodeMetadataNotifier,
    ).thenReturn(ValueNotifier(null));
    when(
      () => mockRenderState.hoveredNodeNotifier,
    ).thenReturn(ValueNotifier(null));
    when(
      () => mockRenderState.hoveredPortNotifier,
    ).thenReturn(ValueNotifier(null));
    when(() => mockRenderState.movementNotifier).thenReturn(MovementNotifier());
    when(
      () => mockRenderState.relationDataNotifier,
    ).thenReturn(ChangeNotifier());
    when(() => mockRenderState.viewStates).thenReturn({});
    when(() => mockRenderState.zOrder).thenReturn([]);
    when(() => mockRenderState.selectedEntities).thenReturn({});
    when(() => mockRenderState.activeEditId).thenReturn(null);
    when(
      () => mockRenderState.activeEditIdNotifier,
    ).thenReturn(activeEditIdNotifier);
    when(() => mockRenderState.nodeShowingFloatingToolbar).thenReturn(null);
    when(
      () => mockRenderState.toolbarOffsetNotifier,
    ).thenReturn(toolbarOffsetNotifier);
    when(
      () => mockRenderState.multiToolbarOffsetNotifier,
    ).thenReturn(multiToolbarOffsetNotifier);
    when(
      () => mockRenderState.activeTextSelectionNotifier,
    ).thenReturn(ValueNotifier(null));
    when(
      () => mockRenderState.currentTextAlignNotifier,
    ).thenReturn(ValueNotifier(TextAlign.center));
    when(() => mockRenderState.draggingNodes).thenReturn({});
    when(
      () => mockRenderState.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRenderState.relations).thenReturn([]);
    when(() => mockRenderState.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(
      () => mockRenderState.relationLookup,
    ).thenReturn(UnmodifiableMapView({}));
    when(() => mockRenderState.isLoading).thenReturn(false);
    when(() => mockRenderState.errorMessage).thenReturn(null);
    when(() => mockRenderState.addListener(any())).thenAnswer((_) {});
    when(() => mockRenderState.removeListener(any())).thenAnswer((_) {});
  });

  tearDown(() {
    copyBuffer.dispose();
    isInitializedNotifier.dispose();
    toolModeNotifier.dispose();
    currentViewNotifier.dispose();
    relationLabelModeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
    showLeftPanelNotifier.dispose();
    showRightPanelNotifier.dispose();
    showBottomPanelNotifier.dispose();
    activeLeftPanelNotifier.dispose();
    activeInspectorTabNotifier.dispose();
    activeEditIdNotifier.dispose();
    toolbarOffsetNotifier.dispose();
    multiToolbarOffsetNotifier.dispose();
  });

  Widget createSubject() {
    return MultiProvider(
      providers: [
        Provider<GraphDataQueryController>.value(value: mockQuery),
        InheritedProvider<GraphDataQuery>.value(value: mockRenderState),
        Provider<CommandQueueProcessor>.value(value: mockCommand),
        ChangeNotifierProvider<NodeRenderState>.value(value: mockRenderState),
        ChangeNotifierProvider<WorkspaceTabsController>.value(
          value: mockTabsController,
        ),
        ChangeNotifierProvider<CopyBuffer>.value(value: copyBuffer),
      ],
      child: const MaterialApp(home: Scaffold(body: GraphCanvas())),
    );
  }

  group('GraphCanvas Root Assembly Tests', () {
    testWidgets('mounts and renders complete modular hierarchy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Verify root architectural components
      expect(find.byType(GraphCanvas), findsOneWidget);
      expect(find.byType(CanvasStageScope), findsOneWidget);
      expect(find.byType(CanvasTemplateDropTarget), findsOneWidget);
      expect(find.byType(CanvasGestureRouter), findsOneWidget);
      expect(find.byType(CanvasCameraHost), findsOneWidget);
      expect(find.byType(CanvasWorldStack), findsOneWidget);
      expect(find.byType(CanvasOverlayLayout), findsOneWidget);

      // Verify all 6 world layers mounted
      expect(find.byType(GridLayer), findsOneWidget);
      expect(find.byType(RelationLayer), findsOneWidget);
      expect(find.byType(NodeLayer), findsOneWidget);
      expect(find.byType(OverlayLayer), findsOneWidget);
      expect(find.byType(PortLayer), findsOneWidget);
      expect(find.byType(ActiveDrawingLayer), findsOneWidget);
    });

    testWidgets(
      'displays loading overlay when session is not yet initialized',
      (tester) async {
        isInitializedNotifier.value = false;

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createSubject());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Transition to initialized
        isInitializedNotifier.value = true;
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('disposes cleanly and calls session.saveViewportState', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Replace subject to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      verify(() => mockSession.saveViewportState()).called(1);
    });
  });
}
