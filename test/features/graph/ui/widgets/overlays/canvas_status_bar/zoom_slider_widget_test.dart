import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/canvas_status_bar/zoom_slider_widget.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

import 'package:centrode/src/rust/domain/base_models.dart' show BoundingBox;

class MockGraphDataQuery extends Mock implements GraphDataQuery {}

class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(Rect.zero);
  });

  group('ZoomSliderWidget', () {
    late ViewportController viewportController;
    late MockGraphDataQuery mockQuery;
    late MockSpatialHashGrid mockSpatial;

    setUp(() {
      mockQuery = MockGraphDataQuery();
      mockSpatial = MockSpatialHashGrid();
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

    testWidgets('renders zoom level percentage and re-center button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<ViewportController>.value(
              value: viewportController,
              child: const ZoomSliderWidget(),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('re-centers scale to 100% when re-center button is pressed', (tester) async {
      // Set initial zoom level to 200% (2.0)
      viewportController.updateScale(2.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<ViewportController>.value(
              value: viewportController,
              child: const ZoomSliderWidget(),
            ),
          ),
        ),
      );

      expect(find.text('200%'), findsOneWidget);

      // Tap re-center button
      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pumpAndSettle();

      expect(viewportController.viewportStateNotifier.value.scale, 1.0);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('re-centers scale to 100% when percentage text is pressed', (tester) async {
      // Set initial zoom level to 50% (0.5)
      viewportController.updateScale(0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<ViewportController>.value(
              value: viewportController,
              child: const ZoomSliderWidget(),
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);

      // Tap percentage text
      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();

      expect(viewportController.viewportStateNotifier.value.scale, 1.0);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
