import 'dart:collection' show UnmodifiableMapView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/presentation/canvas_context_menu_coordinator.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockGraphDataCommand extends Mock implements GraphDataCommand {}

class MockViewportController extends Mock implements ViewportController {}

class MockTabSession extends Mock implements TabSession {}

class MockInteractionContext extends Mock implements InteractionContext {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockHierarchicalSpatialIndex extends Mock
    implements HierarchicalSpatialIndex {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGraphDataQueryController mockQuery;
  late MockGraphDataCommand mockCommand;
  late MockViewportController mockViewport;
  late MockTabSession mockSession;
  late MockInteractionContext mockInteractionContext;
  late MockSpatialHashGrid mockSpatial;
  late MockHierarchicalSpatialIndex mockSpatialIndex;
  late NodeRenderState renderState;

  late TransformationController transformController;
  late ValueNotifier<String> toolModeNotifier;

  setUpAll(() {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
    registerFallbackValue(RawUuid.fromString('node-1'));
  });

  setUp(() {
    mockQuery = MockGraphDataQueryController();
    mockCommand = MockGraphDataCommand();
    mockViewport = MockViewportController();
    mockSession = MockTabSession();
    mockInteractionContext = MockInteractionContext();
    mockSpatial = MockSpatialHashGrid();
    mockSpatialIndex = MockHierarchicalSpatialIndex();
    final mockRelationEngine = MockRelationEngineState();
    when(() => mockRelationEngine.cache).thenReturn({});

    transformController = TransformationController();
    toolModeNotifier = ValueNotifier('select');

    when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
    when(() => mockQuery.spatialIndex).thenReturn(mockSpatialIndex);
    when(() => mockQuery.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationLookup).thenReturn(UnmodifiableMapView({}));
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => mockViewport.transformController,
    ).thenReturn(transformController);
    when(
      () => mockViewport.screenToCanvas(any()),
    ).thenAnswer((inv) => inv.positionalArguments[0] as Offset);
    when(
      () => mockViewport.projectCanvasRectToScreen(any()),
    ).thenAnswer((inv) => inv.positionalArguments[0] as Rect);

    when(() => mockSession.toolModeNotifier).thenReturn(toolModeNotifier);

    when(
      () => mockInteractionContext.activeScope,
    ).thenReturn(const RootViewportScope());
    when(() => mockInteractionContext.zOrder).thenReturn(const []);
    when(() => mockInteractionContext.nodeViewStates).thenReturn({});
    when(() => mockInteractionContext.getNode(any())).thenReturn(null);
    when(() => mockInteractionContext.getSelectedEntities()).thenReturn({});
    when(() => mockInteractionContext.getRelations()).thenReturn(const []);
    when(() => mockInteractionContext.optArea).thenReturn(null);
    when(() => mockInteractionContext.spatialGrid).thenReturn(mockSpatial);
    when(
      () => mockInteractionContext.relationEngine,
    ).thenReturn(mockRelationEngine);

    renderState = NodeRenderState(mockQuery, mockCommand);
  });

  tearDown(() {
    transformController.dispose();
    toolModeNotifier.dispose();
    renderState.dispose();
  });

  group('CanvasContextMenuCoordinator Tests', () {
    test('Suppresses context menu when active editing is in progress', () {
      ContextMenuResolution? emittedResolution;

      final coordinator = CanvasContextMenuCoordinator(
        queryController: mockQuery,
        renderState: renderState,
        viewportController: mockViewport,
        session: mockSession,
        interactionContext: mockInteractionContext,
        onContextMenuResolved: (res) => emittedResolution = res,
      );

      renderState.activeEditIdNotifier.value = RawUuid.fromString(
        'edit-node-1',
      );
      coordinator.handleContextMenuRequest(const Offset(200, 200));

      expect(emittedResolution, isNull);
    });

    test('Suppresses context menu during active drawing mode', () {
      ContextMenuResolution? emittedResolution;

      final coordinator = CanvasContextMenuCoordinator(
        queryController: mockQuery,
        renderState: renderState,
        viewportController: mockViewport,
        session: mockSession,
        interactionContext: mockInteractionContext,
        onContextMenuResolved: (res) => emittedResolution = res,
      );

      toolModeNotifier.value = 'draw';
      coordinator.handleContextMenuRequest(const Offset(200, 200));

      expect(emittedResolution, isNull);
    });

    test('Suppresses context menu while nodes are being dragged', () {
      ContextMenuResolution? emittedResolution;

      final coordinator = CanvasContextMenuCoordinator(
        queryController: mockQuery,
        renderState: renderState,
        viewportController: mockViewport,
        session: mockSession,
        interactionContext: mockInteractionContext,
        onContextMenuResolved: (res) => emittedResolution = res,
      );

      renderState.dragState.setNodeDragging(RawUuid.fromString('node-1'), true);
      coordinator.handleContextMenuRequest(const Offset(200, 200));

      expect(emittedResolution, isNull);
    });

    test(
      'Emits resolution on background click and clears entity selection',
      () {
        ContextMenuResolution? emittedResolution;

        final coordinator = CanvasContextMenuCoordinator(
          queryController: mockQuery,
          renderState: renderState,
          viewportController: mockViewport,
          session: mockSession,
          interactionContext: mockInteractionContext,
          onContextMenuResolved: (res) => emittedResolution = res,
        );

        final testId = RawUuid.fromString('previously-selected');
        final testNode = CommentUiNode(
          id: testId,
          position: Offset.zero,
          text: 'test',
        );
        when(
          () => mockQuery.nodeLookup,
        ).thenReturn(UnmodifiableMapView({testId: testNode}));

        renderState.selectEntities([testId]);
        expect(renderState.selectedEntities, isNotEmpty);

        coordinator.handleContextMenuRequest(const Offset(300, 400));

        expect(emittedResolution, isNotNull);
        expect(emittedResolution!.screenPosition, const Offset(300, 400));
        expect(emittedResolution!.hitNodeId, isNull);
        expect(emittedResolution!.targetNodeRect, isNull);
        expect(renderState.selectedEntities, isEmpty);
      },
    );
  });
}
