import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/nodes.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/shared/domain/raw_uuid.dart';

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

      final copied = node.copyWith(
        state: TaskState.done,
        dueDate: 1620000000000,
      );

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

    test('MediaUiNode creates and maps to Rust correctly', () {
      final id = RawUuid.fromString('media-ffi-1');
      final attachment = Attachment(
        id: 'att-1',
        hash: 'hash123',
        name: 'sample.png',
        mimeType: 'image/png',
        byteSize: 2048,
      );
      final node = MediaUiNode(
        id: id,
        position: const Offset(80, 90),
        size: const Size(200, 150),
        attachment: attachment,
        mediaType: MediaType.image,
      );

      expect(node.tableName, 'MediaNode');
      expect(node.attachment.name, 'sample.png');
      expect(node.mediaType, MediaType.image);

      final rustObj = node.toRust();
      expect(rustObj, isA<Nodes>());

      final asMediaNode = rustObj.maybeMap(
        mediaNode: (m) => m.field0,
        orElse: () => null,
      );

      expect(asMediaNode, isNotNull);
      expect(asMediaNode!.id.key.uuid, id.toUuidString());
      expect(asMediaNode.attachment.name, 'sample.png');
      expect(asMediaNode.attachment.hash, 'hash123');
      expect(asMediaNode.attachment.mimeType, 'image/png');
      expect(asMediaNode.attachment.byteSize, 2048);
    });

    test('InfoUiNode supports multi-attachments', () {
      final attachment1 = Attachment(
        id: 'att-1',
        hash: 'hash1',
        name: 'document.pdf',
        mimeType: 'application/pdf',
        byteSize: 1024 * 50,
      );
      final attachment2 = Attachment(
        id: 'att-2',
        hash: 'hash2',
        name: 'sound.mp3',
        mimeType: 'audio/mp3',
        byteSize: 1024 * 100,
      );

      final node = InfoUiNode(
        position: const Offset(0, 0),
        attachments: [attachment1, attachment2],
      );

      expect(node.attachments.length, 2);
      expect(node.attachments[0].name, 'document.pdf');
      expect(node.attachments[1].name, 'sound.mp3');

      final rustObj = node.toRust();
      final asINode = rustObj.maybeMap(
        iNode: (i) => i.field0,
        orElse: () => null,
      );

      expect(asINode, isNotNull);
      expect(asINode!.attachments.length, 2);
      expect(asINode.attachments[0].name, 'document.pdf');
      expect(asINode.attachments[1].name, 'sound.mp3');
    });
  });
}
