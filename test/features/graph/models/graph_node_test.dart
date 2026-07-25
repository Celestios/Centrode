import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/types.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

void main() {
  group('UiNode', () {
    test('InfoUiNode creates with defaults', () {
      final node = InfoUiNode(position: const Offset(10, 20));

      expect(node.id, isNotNull);
      expect(node.position, const Offset(10, 20));
      expect(node.layer, 'default');
      expect(node.locked, isFalse);
      expect(node.isExpanded, isFalse);
      expect(node.tableName, 'INode');
    });

    test('TaskUiNode creates with defaults', () {
      final node = TaskUiNode(position: const Offset(30, 40));

      expect(node.id, isNotNull);
      expect(node.position, const Offset(30, 40));
      expect(node.layer, 'default');
      expect(node.state, TaskState.todo);
      expect(node.tableName, 'TaskNode');
    });

    test('InfoUiNode copyWith updates fields correctly', () {
      final node = InfoUiNode(
        id: RawUuid.fromString('123'),
        position: const Offset(0, 0),
        layer: 'base',
      );

      final copied = node.copyWith(
        layer: 'top',
        position: const Offset(100, 100),
        locked: true,
      );

      expect(copied.id, RawUuid.fromString('123')); // Unchanged
      expect(copied.layer, 'top'); // Changed
      expect(copied.position, const Offset(100, 100)); // Changed
      expect(copied.locked, isTrue); // Changed
    });

    test('TaskUiNode copyWith updates fields correctly', () {
      final node = TaskUiNode(
        id: RawUuid.fromString('task-1'),
        position: const Offset(0, 0),
        state: TaskState.todo,
      );

      final copied = node.copyWith(state: TaskState.done, dueDate: 1620000000000);

      expect(copied.id, RawUuid.fromString('task-1'));
      expect(copied.state, TaskState.done);
      expect(copied.dueDate, 1620000000000);
      expect(copied.position, const Offset(0, 0));
    });

    test('InfoUiNode toRust generates valid FFI object', () {
      final id = RawUuid.fromString('node-ffi-1');
      final node = InfoUiNode(
        id: id,
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
      expect(asINode!.id.key.uuid, id.toUuidString());
      expect(asINode.layer, 'bg');
      expect(asINode.position.x, 15);
      expect(asINode.position.y, 25);
      expect(asINode.size.width, 100);
      expect(asINode.size.height, 200);
    });

    test('TaskUiNode toRust generates valid FFI object', () {
      final id = RawUuid.fromString('task-ffi-1');
      final node = TaskUiNode(
        id: id,
        position: const Offset(50, 60),
        state: TaskState.inProgress,
      );

      final rustObj = node.toRust();

      final asTaskNode = rustObj.maybeMap(
        taskNode: (taskNode) => taskNode.field0,
        orElse: () => null,
      );

      expect(asTaskNode, isNotNull);
      expect(asTaskNode!.id.key.uuid, id.toUuidString());
      expect(asTaskNode.state, TaskState.inProgress);
      expect(asTaskNode.position.x, 50);
      expect(asTaskNode.position.y, 60);
    });
  });
}
