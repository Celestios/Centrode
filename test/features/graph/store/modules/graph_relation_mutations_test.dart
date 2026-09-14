import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';

void main() {
  group('GraphRelationMutations', () {
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

    test('createRelation inserts into store', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.task, const Offset(100, 100));

      controller.createRelation(
        node1,
        node2,
        fromSide: PortSide.right,
        toSide: PortSide.left,
      );

      expect(queryController.relations.length, 1);
      final rel = queryController.relations.first;
      expect(rel.fromNodeId, node1);
      expect(rel.toNodeId, node2);
      expect(rel.layout?.fromSide, PortSide.right);
      expect(rel.layout?.toSide, PortSide.left);

      await controller.syncEngine.processor.forceFlush();
      expect(
        api.invocationLog.any((l) => l.startsWith('createRelation')),
        isTrue,
      );
    });

    test('deleteRelation removes from store', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.info, const Offset(100, 100));

      controller.createRelation(node1, node2);
      expect(queryController.relations.length, 1);

      final relId = queryController.relations.first.id;

      await controller.deleteRelation(relId);

      expect(queryController.relations.isEmpty, isTrue);

      await controller.syncEngine.processor.forceFlush();
      expect(
        api.invocationLog.any((l) => l.startsWith('deleteRelation')),
        isTrue,
      );
    });

    test(
      'updateRelationLayout updates layout and triggers FFI mutate call',
      () async {
        final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
        final node2 = controller.createNode(
          UiNodes.info,
          const Offset(100, 100),
        );
        final node3 = controller.createNode(
          UiNodes.info,
          const Offset(200, 200),
        );

        controller.createRelation(node1, node2);
        final relId = queryController.relations.first.id;

        controller.updateRelationLayout(
          relId,
          fromNodeId: node1,
          toNodeId: node3,
          fromSide: PortSide.top,
          toSide: PortSide.bottom,
          strategyType: 'bezier',
        );

        final updated = queryController.relationLookup[relId]!;
        expect(updated.fromNodeId, node1);
        expect(updated.toNodeId, node3);
        expect(updated.layout?.fromSide, PortSide.top);
        expect(updated.layout?.toSide, PortSide.bottom);
        expect(updated.layout?.strategyType, 'bezier');

        await controller.syncEngine.processor.forceFlush();
        expect(api.invocationLog.contains('applyEntityMutation'), isTrue);
      },
    );
  });
}
