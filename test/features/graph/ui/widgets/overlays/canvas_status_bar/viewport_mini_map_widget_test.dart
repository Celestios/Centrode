import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/canvas_status_bar/viewport_mini_map_widget.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/base_models.dart' show BoundingBox;

class MockGraphDataQuery extends Mock implements GraphDataQuery {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

class MockNodeRenderState extends Mock implements NodeRenderState {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(Rect.zero);
  });

  group('ViewportMiniMapWidget', () {
    late ViewportController viewportController;
    late MockNodeRenderState renderState;
    late MockGraphDataQuery mockQuery;
    late MockSpatialHashGrid mockSpatial;

    setUp(() {
      mockQuery = MockGraphDataQuery();
      mockSpatial = MockSpatialHashGrid();
      renderState = MockNodeRenderState();

      when(() => renderState.nodeLookup).thenReturn({});
      when(() => renderState.relations).thenReturn({});
      when(() => renderState.addListener(any())).thenReturn(null);
      when(() => renderState.removeListener(any())).thenReturn(null);

      when(() => mockSpatial.queryRect(any())).thenReturn(<RawUuid>{});
      when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
      when(
        () => mockQuery.canvasBounds,
      ).thenReturn(BoundingBox(minX: 0, minY: 0, maxX: 0, maxY: 0));
      when(() => mockQuery.onEntityUpdate).thenAnswer((_) => const Stream.empty());

      viewportController = ViewportController(mockQuery);
      viewportController.updateViewportSize(const Size(800, 600));
    });

    tearDown(() {
      viewportController.dispose();
    });

    testWidgets('tapping minimap moves camera to clicked position', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<ViewportController>.value(value: viewportController),
                ChangeNotifierProvider<NodeRenderState>.value(value: renderState),
              ],
              child: const ViewportMiniMapWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      final initialTranslation =
          viewportController.transformController.value.getTranslation();

      // Tap top-left quadrant of minimap (50, 50)
      await tester.tapAt(
        tester.getTopLeft(find.byType(ViewportMiniMapWidget)) +
            const Offset(50, 50),
      );
      await tester.pump();
      await tester.pump(Duration.zero);

      final newTranslation =
          viewportController.transformController.value.getTranslation();

      // Verify camera translation changed
      expect(newTranslation, isNot(equals(initialTranslation)));
    });
  });
}
