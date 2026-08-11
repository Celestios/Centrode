import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/graph_relation.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  group('UiRelation', () {
    test('InfoUiRelation creates with defaults', () {
      final relation = InfoUiRelation(
        fromNodeId: RawUuid.fromString('node-1'),
        fromNodeTable: 'INode',
        toNodeId: RawUuid.fromString('node-2'),
        toNodeTable: 'TaskNode',
      );

      expect(relation.id, isNotNull);
      expect(relation.fromNodeId, RawUuid.fromString('node-1'));
      expect(relation.toNodeId, RawUuid.fromString('node-2'));
      expect(relation.verb, 'default');
      expect(relation.direction, RelationDirection.forward);
      expect(relation.layer, 'default');
    });

    test('InfoUiRelation copyWith updates fields', () {
      final relation = InfoUiRelation(
        id: RawUuid.fromString('rel-1'),
        fromNodeId: RawUuid.fromString('n1'),
        fromNodeTable: 'INode',
        toNodeId: RawUuid.fromString('n2'),
        toNodeTable: 'INode',
        verb: 'relates_to',
      );

      final copied = relation.copyWith(verb: 'depends_on', direction: RelationDirection.undirected);

      expect(copied.id, RawUuid.fromString('rel-1'));
      expect(copied.fromNodeId, RawUuid.fromString('n1'));
      expect(copied.verb, 'depends_on');
      expect(copied.direction, RelationDirection.undirected);
    });

    test('InfoUiRelation toRust generates valid FFI object', () {
      final relId = RawUuid.fromString('rel-ffi');
      final n1Id = RawUuid.fromString('n1');
      final n2Id = RawUuid.fromString('n2');
      final relation = InfoUiRelation(
        id: relId,
        fromNodeId: n1Id,
        fromNodeTable: 'INode',
        toNodeId: n2Id,
        toNodeTable: 'TaskNode',
        verb: 'blocks',
        direction: RelationDirection.forward,
      );

      final rustObj = relation.toRust();
      expect(rustObj.key.key.uuid, relId.toUuidString());
      expect(rustObj.in_.key.uuid, n1Id.toUuidString());
      expect(rustObj.out.key.uuid, n2Id.toUuidString());
      expect(rustObj.fields.verb, 'blocks');
      expect(rustObj.fields.direction, RelationDirection.forward);
    });
  });
}
