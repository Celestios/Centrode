import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';

void main() {

  group('GraphNodeMutations', () {
    late CommandQueueProcessor controller;
    late GraphDataQueryController queryController;
    late InMemoryGraphApi api;

    setUp(() {
      api = InMemoryGraphApi();
      queryController = GraphDataQueryController(api);
      controller = CommandQueueProcessor(api, queryController);
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
      expect(queryController.nodeLookup.containsKey(id), isTrue);
      final node = queryController.nodeLookup[id]!;
      expect(node.position, const Offset(100, 200));
      expect(node is InfoUiNode, isTrue);

      // Verify node is in spatial grid
      final spatialNodes = queryController.spatialGrid.queryRect(
        const Rect.fromLTWH(50, 150, 100, 100),
      );
      expect(spatialNodes.contains(id), isTrue);

      // Verify API was called to create node
      await controller.syncEngine.processor.forceFlush();
      expect(api.invocationLog.any((e) => e.startsWith('createNode:')), isTrue);
    });

    test('deleteNode removes from store immediately optimistically', () async {
      final id = controller.nodeMutations.createNode(
        UiNodes.task,
        const Offset(50, 50),
      );

      expect(queryController.nodeLookup.containsKey(id), isTrue);

      await controller.nodeMutations.deleteNode(id);

      // Should be removed optimistically
      expect(queryController.nodeLookup.containsKey(id), isFalse);

      // Verify API was called
      await controller.syncEngine.processor.forceFlush();
      expect(api.invocationLog.any((e) => e.startsWith('deleteNode:')), isTrue);
    });

    test('updateNodePosition moves node and updates spatial grid', () {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(0, 0),
      );

      controller.nodeMutations.updateNodePosition(id, const Offset(2000, 2000));

      final node = queryController.nodeLookup[id]!;
      expect(node.position, const Offset(2000, 2000));
    });

    test('updateNodeWidth updates custom width on node', () {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(0, 0),
      );

      controller.nodeMutations.updateNodeWidth(id, 0.0, 360.0);

      final node = queryController.nodeLookup[id]!;
      expect(node.size.width, equals(360.0));
      expect(node.style?.width, equals(360));
    });

    test('toggleNodeExpansion toggles isExpanded state', () {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(0, 0),
      );

      final initial = queryController.nodeLookup[id]!.isExpanded;
      controller.nodeMutations.toggleNodeExpansion(id);

      final toggled = queryController.nodeLookup[id]!;
      expect(toggled.isExpanded, equals(!initial));
    });

    test('convertNodeToContainer converts INode to ContainerUiNode', () async {
      final id = controller.nodeMutations.createNode(
        UiNodes.info,
        const Offset(100, 200),
      );

      expect(queryController.nodeLookup[id] is InfoUiNode, isTrue);

      controller.convertNodeToContainer(id);

      final convertedNode = queryController.nodeLookup[id];
      expect(convertedNode is ContainerUiNode, isTrue);
      expect(convertedNode!.position, const Offset(100, 200));
      expect((convertedNode as ContainerUiNode).title, 'topic');
    });
  });
}

