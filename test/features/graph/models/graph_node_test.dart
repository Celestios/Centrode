import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';

void main() {
  group('UiNode', () {
    test('InfoUiNode creates with defaults', () {
      final node = InfoUiNode(position: const Offset(10, 20));

      expect(node.id, isNotEmpty);
      expect(node.position, const Offset(10, 20));
      expect(node.layer, 'default');
      expect(node.locked, isFalse);
      expect(node.isExpanded, isFalse);
      expect(node.tableName, 'INode');
    });

    test('TaskUiNode creates with defaults', () {
      final node = TaskUiNode(position: const Offset(30, 40));

      expect(node.id, isNotEmpty);
      expect(node.position, const Offset(30, 40));
      expect(node.layer, 'default');
      expect(node.state, 'Not Done');
      expect(node.tableName, 'TaskNode');
    });

    test('InfoUiNode copyWith updates fields correctly', () {
      final node = InfoUiNode(
        id: '123',
        position: const Offset(0, 0),
        layer: 'base',
      );

      final copied = node.copyWith(
        layer: 'top',
        position: const Offset(100, 100),
        locked: true,
      );

      expect(copied.id, '123'); // Unchanged
      expect(copied.layer, 'top'); // Changed
      expect(copied.position, const Offset(100, 100)); // Changed
      expect(copied.locked, isTrue); // Changed
    });

    test('TaskUiNode copyWith updates fields correctly', () {
      final node = TaskUiNode(
        id: 'task-1',
        position: const Offset(0, 0),
        state: 'Not Done',
      );

      final copied = node.copyWith(state: 'Done', dueDate: 1620000000000);

      expect(copied.id, 'task-1');
      expect(copied.state, 'Done');
      expect(copied.dueDate, 1620000000000);
      expect(copied.position, const Offset(0, 0));
    });

    test('InfoUiNode toRust generates valid FFI object', () {
      final node = InfoUiNode(
        id: 'node-ffi-1',
        position: const Offset(15, 25),
        layer: 'bg',
        size: const Size(100, 200),
      );

      final rustObj = node.toRust();
      expect(rustObj, isA<Nodes>());

      final asINode = rustObj.maybeMap(
        iNode: (iNode) => iNode.field0,
        orElse: () => null,
      );

      expect(asINode, isNotNull);
      expect(asINode!.id.key, 'node-ffi-1');
      expect(asINode.layer, 'bg');
      expect(asINode.position.x, 15);
      expect(asINode.position.y, 25);
      expect(asINode.size.width, 100);
      expect(asINode.size.height, 200);
    });

    test('TaskUiNode toRust generates valid FFI object', () {
      final node = TaskUiNode(
        id: 'task-ffi-1',
        position: const Offset(50, 60),
        state: 'In Progress',
      );

      final rustObj = node.toRust();

      final asTaskNode = rustObj.maybeMap(
        taskNode: (taskNode) => taskNode.field0,
        orElse: () => null,
      );

      expect(asTaskNode, isNotNull);
      expect(asTaskNode!.id.key, 'task-ffi-1');
      expect(asTaskNode.state, 'In Progress');
      expect(asTaskNode.position.x, 50);
      expect(asTaskNode.position.y, 60);
    });
  });
}
