import 'dart:collection' show UnmodifiableMapView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/presentation/canvas_lifecycle_coordinator.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/store/modules/graph_node_mutations.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockGraphDataCommand extends Mock implements GraphDataCommand {}

class MockCommandQueueProcessor extends Mock implements CommandQueueProcessor {}

class MockGraphNodeMutations extends Mock implements GraphNodeMutations {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockTabSession extends Mock implements TabSession {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockHierarchicalSpatialIndex extends Mock
    implements HierarchicalSpatialIndex {}

class MockTickerProvider extends Mock implements TickerProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGraphDataQueryController mockQuery;
  late MockGraphDataCommand mockCommand;
  late MockCommandQueueProcessor mockCmdProcessor;
  late MockGraphNodeMutations mockNodeMutations;
  late MockRelationEngineState mockRelationEngine;
  late MockTabSession mockSession;
  late MockSpatialHashGrid mockSpatial;
  late MockHierarchicalSpatialIndex mockSpatialIndex;
  late NodeRenderState renderState;

  late ValueNotifier<bool> isLoadingNotifier;
  late ValueNotifier<String> toolModeNotifier;
  late ValueNotifier<String> brushColorNotifier;
  late ValueNotifier<double> brushThicknessNotifier;
  late ValueNotifier<String> brushTypeNotifier;
  late ValueNotifier<BoundingBox> canvasBoundsNotifier;

  setUpAll(() {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
    registerFallbackValue(RawUuid.fromString('node-1'));
  });

  setUp(() {
    mockQuery = MockGraphDataQueryController();
    mockCommand = MockGraphDataCommand();
    mockCmdProcessor = MockCommandQueueProcessor();
    mockNodeMutations = MockGraphNodeMutations();
    mockRelationEngine = MockRelationEngineState();
    mockSession = MockTabSession();
    mockSpatial = MockSpatialHashGrid();
    mockSpatialIndex = MockHierarchicalSpatialIndex();

    isLoadingNotifier = ValueNotifier<bool>(true);
    toolModeNotifier = ValueNotifier<String>('select');
    brushColorNotifier = ValueNotifier<String>('#00E5FF');
    brushThicknessNotifier = ValueNotifier<double>(4.0);
    brushTypeNotifier = ValueNotifier<String>('pen');
    canvasBoundsNotifier = ValueNotifier<BoundingBox>(
      BoundingBox(minX: 0, minY: 0, maxX: 1000, maxY: 1000),
    );

    when(() => mockQuery.isLoadingNotifier).thenReturn(isLoadingNotifier);
    when(() => mockQuery.isLoading).thenAnswer((_) => isLoadingNotifier.value);
    when(
      () => mockQuery.canvasBounds,
    ).thenAnswer((_) => canvasBoundsNotifier.value);
    when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
    when(() => mockQuery.spatialIndex).thenReturn(mockSpatialIndex);
    when(() => mockQuery.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationLookup).thenReturn(UnmodifiableMapView({}));
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockQuery.relationEngine).thenReturn(mockRelationEngine);

    when(() => mockCmdProcessor.nodeMutations).thenReturn(mockNodeMutations);
    when(() => mockCmdProcessor.getSavedViewportState()).thenReturn(null);

    ViewportController? boundVp;
    when(() => mockSession.toolModeNotifier).thenReturn(toolModeNotifier);
    when(() => mockSession.brushColorNotifier).thenReturn(brushColorNotifier);
    when(
      () => mockSession.brushThicknessNotifier,
    ).thenReturn(brushThicknessNotifier);
    when(() => mockSession.brushTypeNotifier).thenReturn(brushTypeNotifier);
    when(() => mockSession.viewportController).thenAnswer((_) => boundVp);
    when(() => mockSession.viewportController = any()).thenAnswer((inv) {
      boundVp = inv.positionalArguments[0] as ViewportController?;
      return boundVp;
    });
    when(() => mockSession.saveViewportState()).thenAnswer((_) async {});

    renderState = NodeRenderState(mockQuery, mockCommand);
  });

  tearDown(() {
    isLoadingNotifier.dispose();
    toolModeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
    canvasBoundsNotifier.dispose();
    renderState.dispose();
  });

  group('CanvasLifecycleCoordinator Tests', () {
    test(
      'Initializes in awaitingDataOrLayout phase when isLoading is true',
      () {
        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        expect(coordinator.phase, CanvasLifecyclePhase.awaitingDataOrLayout);
        expect(coordinator.viewportController, isNotNull);
        expect(coordinator.interactionController, isNotNull);
        expect(coordinator.drawingInterceptor, isNotNull);

        coordinator.dispose();
      },
    );

    test(
      'Defers auto-framing until both size is known and isLoading is false',
      () {
        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        // Sizing occurs first, but query is still loading
        coordinator.updateViewportDimensions(const Size(800, 600));
        expect(coordinator.phase, CanvasLifecyclePhase.awaitingDataOrLayout);

        // Loading completes
        isLoadingNotifier.value = false;
        expect(coordinator.phase, CanvasLifecyclePhase.autoFramed);

        coordinator.dispose();
      },
    );

    test(
      'Restores saved viewport state when present instead of auto-framing',
      () {
        when(() => mockCmdProcessor.getSavedViewportState()).thenReturn(
          const ViewportState(
            xOffset: 120.0,
            yOffset: 240.0,
            zoomLevel: 1.5,
            activeView: 'canvas',
          ),
        );

        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        isLoadingNotifier.value = false;
        coordinator.updateViewportDimensions(const Size(1024, 768));

        expect(coordinator.phase, CanvasLifecyclePhase.restoredFromSaved);

        final matrix = coordinator.viewportController.transformController.value;
        expect(matrix.getTranslation().x, closeTo(120.0, 0.001));
        expect(matrix.getTranslation().y, closeTo(240.0, 0.001));
        expect(matrix.getMaxScaleOnAxis(), closeTo(1.5, 0.001));

        coordinator.dispose();
      },
    );

    test('Attaches and detaches vsync correctly', () {
      final coordinator = CanvasLifecycleCoordinator(
        session: mockSession,
        queryController: mockQuery,
        commandProcessor: mockCmdProcessor,
        renderState: renderState,
      );

      final mockVsync = MockTickerProvider();
      coordinator.attachVsync(mockVsync);
      expect(coordinator.viewportController.vsync, mockVsync);

      coordinator.detachVsync();
      expect(coordinator.viewportController.vsync, isNull);

      coordinator.dispose();
    });

    test(
      'Suppresses container zoom gestures while nodes are being dragged',
      () {
        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        expect(coordinator.viewportController.isGestureSuppressed, isFalse);

        renderState.dragState.setNodeDragging(
          RawUuid.fromString('node-1'),
          true,
        );
        expect(coordinator.viewportController.isGestureSuppressed, isTrue);

        renderState.dragState.setNodeDragging(
          RawUuid.fromString('node-1'),
          false,
        );
        expect(coordinator.viewportController.isGestureSuppressed, isFalse);

        coordinator.dispose();
      },
    );

    test(
      'Container open state changed triggers hover clears, mutations and relation routing',
      () {
        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        renderState.hoveredNodeNotifier.value = RawUuid.fromString('node-1');
        renderState.hoveredPortNotifier.value = const Port(
          side: PortSide.top,
          type: PortType.middle,
          index: 0,
          position: Offset.zero,
          edgePosition: Offset.zero,
        );

        final targetId = RawUuid.fromString('container-1');
        coordinator.viewportController.onContainerOpenStateChanged?.call(
          targetId,
          Offset.zero,
          const Size(200, 200),
          true,
        );

        expect(renderState.hoveredNodeNotifier.value, isNull);
        expect(renderState.hoveredPortNotifier.value, isNull);
        verify(
          () => mockNodeMutations.setContainerClosed(targetId, true),
        ).called(1);
        verify(() => mockRelationEngine.onNodeMoved(targetId)).called(1);

        coordinator.dispose();
      },
    );

    test(
      'flushPendingSave delegates immediately to session.saveViewportState',
      () async {
        final coordinator = CanvasLifecycleCoordinator(
          session: mockSession,
          queryController: mockQuery,
          commandProcessor: mockCmdProcessor,
          renderState: renderState,
        );

        await coordinator.flushPendingSave();
        verify(() => mockSession.saveViewportState()).called(1);

        coordinator.dispose();
      },
    );

    test('dispose flushes state and unhooks listeners cleanly', () {
      final coordinator = CanvasLifecycleCoordinator(
        session: mockSession,
        queryController: mockQuery,
        commandProcessor: mockCmdProcessor,
        renderState: renderState,
      );

      coordinator.dispose();
      expect(coordinator.phase, CanvasLifecyclePhase.disposed);
      verify(() => mockSession.saveViewportState()).called(1);
      verify(() => mockSession.viewportController = null).called(1);
    });
  });
}
