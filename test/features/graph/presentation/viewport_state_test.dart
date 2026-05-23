import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/store/modules/graph_spatial.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show BoundingBox;
import 'package:mycelium/features/graph/models/models.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}
class MockSpatialHashGrid extends Mock implements SpatialHashGrid {}

void main() {
  setUpAll(() {
    registerFallbackValue(Rect.zero);
  });

  group('ViewportController', () {
    late ViewportController controller;
    late MockGraphDataQuery mockQuery;
    late MockSpatialHashGrid mockSpatial;
    late ValueNotifier<BoundingBox> mockBoundsNotifier;
    late Stream<GraphEntityUpdate> mockEntityUpdates;

    setUp(() {
      mockQuery = MockGraphDataQuery();
      mockSpatial = MockSpatialHashGrid();
      mockBoundsNotifier = ValueNotifier(BoundingBox(minX: 0, minY: 0, maxX: 100, maxY: 100));
      mockEntityUpdates = const Stream.empty();

      when(() => mockQuery.spatialGrid).thenReturn(mockSpatial);
      when(() => mockQuery.canvasBounds).thenReturn(mockBoundsNotifier);
      when(() => mockQuery.onEntityUpdate).thenAnswer((_) => mockEntityUpdates);
      when(() => mockSpatial.queryRect(any())).thenReturn(<String>{'node-1'});

      controller = ViewportController(mockQuery);
    });

    tearDown(() {
      controller.dispose();
    });

    test('updateViewportSize sets dimensions and triggers math', () {
      controller.updateViewportSize(const Size(800, 600));

      expect(controller.viewportStateNotifier.value.viewportSize, const Size(800, 600));
      expect(controller.visibleNodeIds.value.contains('node-1'), isTrue);
    });

    test('focusOnBounds centers camera properly', () {
      controller.updateViewportSize(const Size(1000, 1000));
      
      // Box is 0,0 to 100,100 -> Center is 50,50
      // Viewport is 1000x1000 -> Center is 500,500
      // We want to translate camera by +450, +450 to place (50,50) at (500,500)
      controller.focusOnBounds(BoundingBox(minX: 0, minY: 0, maxX: 100, maxY: 100));

      final transform = controller.transformController.value;
      final translation = transform.getTranslation();

      expect(translation.x, 450);
      expect(translation.y, 450);
    });

    test('elastic margins expand boundaries when node coordinates exceed padding', () {
      controller.updateViewportSize(const Size(100, 100));
      // Trigger calculation
      mockBoundsNotifier.value = BoundingBox(minX: -500, minY: -500, maxX: 500, maxY: 500);
      
      final margins = controller.elasticMargins.value;
      
      // Node Left Bound = 500 (since minX=-500) + padding
      // Margin Left should be > 500
      expect(margins.left, greaterThanOrEqualTo(500));
      expect(margins.right, greaterThanOrEqualTo(500));
    });
  });
}
