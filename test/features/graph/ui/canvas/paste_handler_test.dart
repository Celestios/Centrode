import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/ui/canvas/paste_handler.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/models/models.dart';

void main() {
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

  group('pasteTextToCanvas', () {
    test('empty text creates no nodes', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.isEmpty, isTrue);
    });

    test('whitespace-only text creates no nodes', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '   \n  \n  ',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.isEmpty, isTrue);
    });

    test('plain text creates a single node', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: 'Hello world',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.length, equals(1));
      final node = queryController.nodeLookup.values.first;
      expect(node.content.text, contains('Hello world'));
    });

    test('heading creates a single node with heading content', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# My Heading',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.length, equals(1));
      final node = queryController.nodeLookup.values.first;
      expect(node.content.text, contains('My Heading'));
    });

    test('multi-line plain text creates a single node', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: 'Line 1\nLine 2\nLine 3',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.length, equals(1));
    });

    test(
      'heading with children creates tree of nodes with relations',
      () async {
        await pasteTextToCanvas(
          dataController: controller,
          text: '# Root\n\n- Child 1\n- Child 2',
          canvasPosition: const Offset(100, 100),
        );
        await controller.flush();
        expect(queryController.nodeLookup.length, equals(3));
        expect(queryController.relationLookup.length, equals(2));
      },
    );

    test('nested headings create deep tree', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Level 1\n\n## Level 2\n\n### Level 3',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(3));
      expect(queryController.relationLookup.length, equals(2));
    });

    test('bullet items become children of preceding heading', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Tasks\n\n- Item A\n- Item B',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(3));
      expect(queryController.relationLookup.length, equals(2));
    });

    test('code blocks are preserved in node content', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '```\nconst x = 1;\n```',
        canvasPosition: const Offset(100, 100),
      );
      expect(queryController.nodeLookup.length, equals(1));
      final node = queryController.nodeLookup.values.first;
      expect(node.content.text, contains('const x = 1;'));
    });

    test('CRLF line endings are handled', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Heading\r\nParagraph text',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(2));
    });

    test('multiple root headings create sibling trees', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Tree A\n\nA child\n\n# Tree B\n\nB child',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(4));
      expect(queryController.relationLookup.length, equals(2));
    });
  });
}
