import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;

Nodes createSampleNode(String idStr, {int x = 0, int y = 0}) {
  return Nodes.iNode(
    INode(
      id: parseTypedRecordId('INode', RawUuid.fromString(idStr)),
      content: ContentFactory.empty(),
      layer: 'default',
      position: frb.Coordinates(x: x, y: y),
      size: const frb.Size(width: 160, height: 80),
      expandable: false,
      isExpanded: false,
      locked: false,
      tags: const [],
      aliases: const [],
      comments: const [],
      attachments: const [],
      significance: 0,
      createdAt: 0,
      updatedAt: 0,
      lineCount: 1,
    ),
  );
}

IRelation createSampleRelation(String idStr, TypedRecordId from, TypedRecordId to) {
  return IRelation(
    key: parseTypedRecordId('IRelation', RawUuid.fromString(idStr)),
    in_: from,
    out: to,
    fields: const IRelationFields(
      verb: 'link',
      layer: 'default',
      direction: RelationDirection.forward,
      createdAt: 0,
      updatedAt: 0,
    ),
  );
}

void runGraphApiContractTests(
  String runnerName,
  FutureOr<GraphApi> Function() factory,
) {
  group('GraphApi Contract Suite [$runnerName]', () {
    late GraphApi api;

    setUp(() async {
      api = await factory();
    });

    tearDown(() async {
      await api.close();
    });

    test('Node Lifecycle: create -> get -> update -> delete', () async {
      final node = createSampleNode('node-1', x: 100, y: 200);
      final id = (node.field0 as INode).id;

      await api.createNode(input: node);

      final fetched = await api.getNode(id: id);
      expect(fetched, isNotNull);
      expect((fetched!.field0 as INode).id.key.uuid, equals(id.key.uuid));

      final updatedNode = createSampleNode('node-1', x: 300, y: 400);
      await api.updateNode(input: updatedNode);

      final afterUpdate = await api.getNode(id: id);
      expect((afterUpdate!.field0 as INode).position.x, equals(300));
      expect((afterUpdate.field0 as INode).position.y, equals(400));

      await api.deleteNodeEntry(id: id);
      final afterDelete = await api.getNode(id: id);
      expect(afterDelete, isNull);
    });

    test('Cascading Deletion: Deleting node automatically purges connected relations', () async {
      final nodeA = createSampleNode('node-A');
      final nodeB = createSampleNode('node-B');
      final idA = (nodeA.field0 as INode).id;
      final idB = (nodeB.field0 as INode).id;

      await api.createNode(input: nodeA);
      await api.createNode(input: nodeB);

      final relation = createSampleRelation('rel-1', idA, idB);
      await api.createRelation(input: relation);

      final snapshotBefore = await api.getGraphSnapshot();
      expect(snapshotBefore.nodes.length, equals(2));
      expect(snapshotBefore.relations.length, equals(1));

      // Delete Node A -> Relation should be cascaded
      await api.deleteNodeEntry(id: idA);

      final snapshotAfter = await api.getGraphSnapshot();
      expect(snapshotAfter.nodes.length, equals(1));
      expect(snapshotAfter.relations.length, equals(0));
    });
  });
}
