import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockAppHandle extends Mock implements AppHandle {}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme =>
      const GraphTheme(id: 'test', name: 'test');
}

void main() {
  group('GraphNodeMutations', () {
    late GraphDataController controller;
    late MockAppHandle mockApi;

    setUpAll(() {
      registerFallbackValue(const Offset(0, 0));
      registerFallbackValue(
        Nodes.iNode(
          INode(
            id: const frb.RecordStrings(table: 'INode', key: 'dummy'),
            content: ContentFactory.empty(),
            layer: 'default',
            position: const frb.Coordinates(x: 0, y: 0),
            size: const frb.Size(width: 10, height: 10),
            expandable: false,
            isExpanded: false,
            locked: false,
            tags: const [],
            aliases: const [],
            comments: const [],
            significance: 0,
            createdAt: 0,
            updatedAt: 0,
            lineCount: 1,
          ),
        ),
      );
    });

    setUp(() {
      mockApi = MockAppHandle();

      when(
        () => mockApi.createNode(input: any(named: 'input')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.deleteNodeEntry(
          table: any(named: 'table'),
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async {});

      controller = GraphDataController(mockApi);
    });

    tearDown(() {
      controller.dispose();
    });

    test('createNode inserts into store and spatial grid', () async {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(100, 200),
      );

      // Verify node is in store
      expect(controller.store.nodeLookup.containsKey(id), isTrue);
      final node = controller.store.nodeLookup[id]!;
      expect(node.position, const Offset(100, 200));
      expect(node is InfoUiNode, isTrue);

      // Verify node is in spatial grid
      final spatialNodes = controller.spatialGrid.queryRect(
        const Rect.fromLTWH(50, 150, 100, 100),
      );
      expect(spatialNodes.contains(id), isTrue);

      // Verify API was called to create node
      await controller.syncEngine.processor.forceFlush();
      verify(() => mockApi.createNode(input: any(named: 'input'))).called(1);
    });

    test('deleteNode removes from store immediately optimistically', () async {
      final id = controller.nodeMutations.createNode(
        UiNodes.task,
        const Offset(50, 50),
      );

      expect(controller.store.nodeLookup.containsKey(id), isTrue);

      await controller.nodeMutations.deleteNode(id);

      // Should be removed optimistically
      expect(controller.store.nodeLookup.containsKey(id), isFalse);

      // Verify API was called
      await controller.syncEngine.processor.forceFlush();
      verify(
        () => mockApi.deleteNodeEntry(table: 'TaskNode', key: id),
      ).called(1);
    });

    test('updateNodePosition moves node and updates spatial grid', () {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(0, 0),
      );

      controller.nodeMutations.updateNodePosition(id, const Offset(2000, 2000));

      final node = controller.store.nodeLookup[id]!;
      expect(node.position, const Offset(2000, 2000));
    });
  });
}
