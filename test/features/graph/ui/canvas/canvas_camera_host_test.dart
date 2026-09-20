import 'dart:collection' show UnmodifiableMapView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/ui/canvas/canvas_camera_host.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/shared/widgets/canvas_interactive_viewer.dart';

class MockGraphDataQueryController extends Mock
    implements GraphDataQueryController {}

class MockGraphDataCommand extends Mock implements GraphDataCommand {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockHierarchicalSpatialIndex extends Mock
    implements HierarchicalSpatialIndex {}

class MockRelationEngineState extends Mock implements RelationEngineState {}

class MockInteractionController extends Mock implements InteractionController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGraphDataQueryController mockQuery;
  late MockGraphDataCommand mockCommand;
  late MockSpatialHashGrid mockSpatial;
  late MockHierarchicalSpatialIndex mockSpatialIndex;
  late MockRelationEngineState mockRelationEngine;
  late NodeRenderState renderState;
  late ViewportController viewportController;
  late MockInteractionController mockInteraction;
  late ValueNotifier<bool> panScaleEnabledNotifier;
  late ValueNotifier<Offset> elasticOverscrollNotifier;

  setUpAll(() {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
  });

  setUp(() {
    mockQuery = MockGraphDataQueryController();
    mockCommand = MockGraphDataCommand();
    mockSpatial = MockSpatialHashGrid();
    mockSpatialIndex = MockHierarchicalSpatialIndex();
    mockRelationEngine = MockRelationEngineState();
    mockInteraction = MockInteractionController();

    when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
    when(() => mockQuery.spatialIndex).thenReturn(mockSpatialIndex);
    when(() => mockQuery.nodeLookup).thenReturn(UnmodifiableMapView({}));
    when(() => mockQuery.relationLookup).thenReturn(UnmodifiableMapView({}));
    when(
      () => mockQuery.canvasBounds,
    ).thenReturn(BoundingBox(minX: 0, minY: 0, maxX: 1000, maxY: 1000));
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockQuery.relationEngine).thenReturn(mockRelationEngine);

    renderState = NodeRenderState(mockQuery, mockCommand);
    viewportController = ViewportController(mockQuery);

    panScaleEnabledNotifier = ValueNotifier<bool>(true);
    elasticOverscrollNotifier = ValueNotifier<Offset>(Offset.zero);

    when(
      () => mockInteraction.panScaleEnabled,
    ).thenReturn(panScaleEnabledNotifier);
  });

  tearDown(() {
    viewportController.dispose();
    renderState.dispose();
    panScaleEnabledNotifier.dispose();
    elasticOverscrollNotifier.dispose();
  });

  group('CanvasCameraHost Tests', () {
    testWidgets(
      'Gating permits pan and scale when idle, not editing, and not transitioning',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: CanvasCameraHost(
                  viewportController: viewportController,
                  interactionController: mockInteraction,
                  renderState: renderState,
                  elasticOverscrollNotifier: elasticOverscrollNotifier,
                  staticChild: Container(
                    key: const Key('static_child'),
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        final viewer = tester.widget<CanvasInteractiveViewer>(
          find.byType(CanvasInteractiveViewer),
        );
        expect(viewer.panEnabled, isTrue);
        expect(viewer.scaleEnabled, isTrue);
      },
    );

    testWidgets('Gating disables pan and scale when active editing is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CanvasCameraHost(
                viewportController: viewportController,
                interactionController: mockInteraction,
                renderState: renderState,
                elasticOverscrollNotifier: elasticOverscrollNotifier,
                staticChild: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      renderState.activeEditIdNotifier.value = RawUuid.fromString('edit-node');
      await tester.pump();

      final viewer = tester.widget<CanvasInteractiveViewer>(
        find.byType(CanvasInteractiveViewer),
      );
      expect(viewer.panEnabled, isFalse);
      expect(viewer.scaleEnabled, isFalse);
    });

    testWidgets('Gating disables pan and scale when transitioning is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CanvasCameraHost(
                viewportController: viewportController,
                interactionController: mockInteraction,
                renderState: renderState,
                elasticOverscrollNotifier: elasticOverscrollNotifier,
                staticChild: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      viewportController.isTransitioningNotifier.value = true;
      await tester.pump();

      final viewer = tester.widget<CanvasInteractiveViewer>(
        find.byType(CanvasInteractiveViewer),
      );
      expect(viewer.panEnabled, isFalse);
      expect(viewer.scaleEnabled, isFalse);
    });

    testWidgets('Preserves static child across camera gating state mutations', (
      tester,
    ) async {
      int staticChildBuildCount = 0;

      final staticWidget = Builder(
        builder: (context) {
          staticChildBuildCount++;
          return Container(color: Colors.red);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CanvasCameraHost(
                viewportController: viewportController,
                interactionController: mockInteraction,
                renderState: renderState,
                elasticOverscrollNotifier: elasticOverscrollNotifier,
                staticChild: staticWidget,
              ),
            ),
          ),
        ),
      );

      expect(staticChildBuildCount, 1);

      // Mutate gating state multiple times
      renderState.activeEditIdNotifier.value = RawUuid.fromString('edit-1');
      await tester.pump();

      viewportController.isTransitioningNotifier.value = true;
      await tester.pump();

      viewportController.isTransitioningNotifier.value = false;
      await tester.pump();

      // Static child was NOT rebuilt
      expect(staticChildBuildCount, 1);
    });
  });
}
