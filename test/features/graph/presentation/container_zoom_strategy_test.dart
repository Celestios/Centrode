import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/strategies/container_zoom_strategy.dart';
import 'package:centrode/features/graph/presentation/strategies/node_layout_strategy.dart';

void main() {
  group('DefaultContainerZoomStrategy', () {
    const strategy = DefaultContainerZoomStrategy();
    const layoutStrategy = DefaultNodeLayoutStrategy();

    test('checkZoomIn returns null when container is already open', () {
      final container = ContainerUiNode(
        id: RawUuid.v4(),
        title: 'Open Container',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        isClosed: false,
        childCount: 0,
      );

      final result = strategy.checkZoomIn(
        node: container,
        nodeLookup: {container.id: container},
        currentScale: 1.0,
        viewportSize: const Size(1920, 1080),
        cursorCanvas: const Offset(150, 150),
        layoutStrategy: layoutStrategy,
      );

      expect(result, isNull);
    });

    test('checkZoomIn triggers when rendered screen width exceeds 180px and cursor is inside', () {
      final container = ContainerUiNode(
        id: RawUuid.v4(),
        title: 'Closed Container',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        isClosed: true,
        childCount: 0,
      );

      final result = strategy.checkZoomIn(
        node: container,
        nodeLookup: {container.id: container},
        currentScale: 2.0, // rendered width exceeds 180px
        viewportSize: const Size(1920, 1080),
        cursorCanvas: const Offset(150, 150),
        layoutStrategy: layoutStrategy,
      );

      expect(result, isNotNull);
      expect(result!.nodeSize.width, isPositive);
      expect(result.internalSize.width, 1600.0);
    });

    test('checkZoomIn returns null when rendered screen width is below 180px', () {
      final container = ContainerUiNode(
        id: RawUuid.v4(),
        title: 'Small Container',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        isClosed: true,
        childCount: 0,
      );

      final result = strategy.checkZoomIn(
        node: container,
        nodeLookup: {container.id: container},
        currentScale: 0.1, // rendered width < 180px
        viewportSize: const Size(1920, 1080),
        cursorCanvas: const Offset(150, 150),
        layoutStrategy: layoutStrategy,
      );

      expect(result, isNull);
    });
  });
}
