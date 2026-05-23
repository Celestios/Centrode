import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';

void main() {
  group('UiRelation', () {
    test('InfoUiRelation creates with defaults', () {
      final relation = InfoUiRelation(
        fromNodeId: 'node-1',
        fromNodeTable: 'INode',
        toNodeId: 'node-2',
        toNodeTable: 'TaskNode',
      );

      expect(relation.id, isNotEmpty);
      expect(relation.fromNodeId, 'node-1');
      expect(relation.toNodeId, 'node-2');
      expect(relation.verb, 'default');
      expect(relation.directionless, isFalse);
      expect(relation.layer, 'default');
    });

    test('InfoUiRelation copyWith updates fields', () {
      final relation = InfoUiRelation(
        id: 'rel-1',
        fromNodeId: 'n1',
        fromNodeTable: 'INode',
        toNodeId: 'n2',
        toNodeTable: 'INode',
        verb: 'relates_to',
      );

      final copied = relation.copyWith(
        verb: 'depends_on',
        directionless: true,
      );

      expect(copied.id, 'rel-1');
      expect(copied.fromNodeId, 'n1');
      expect(copied.verb, 'depends_on');
      expect(copied.directionless, isTrue);
    });

    test('InfoUiRelation toRust generates valid FFI object', () {
      final relation = InfoUiRelation(
        id: 'rel-ffi',
        fromNodeId: 'n1',
        fromNodeTable: 'INode',
        toNodeId: 'n2',
        toNodeTable: 'TaskNode',
        verb: 'blocks',
        directionless: false,
      );

      final rustObj = relation.toRust();
      expect(rustObj.key, 'rel-ffi');
      expect(rustObj.in_, 'INode:n1');
      expect(rustObj.out, 'TaskNode:n2');
      expect(rustObj.fields.verb, 'blocks');
      expect(rustObj.fields.directionless, isFalse);
    });
  });
}
