import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/ui/canvas/paste_handler.dart';
import 'package:mycelium/features/graph/store/graph_data_query_controller.dart';
import 'package:mycelium/features/graph/store/command_queue_processor.dart';
import 'package:mycelium/features/graph/store/graph_api.dart';
import 'package:mycelium/src/rust/domain/snapshot.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/relations.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';

class MockGraphApi extends Mock implements GraphApi {}

void main() {
  late CommandQueueProcessor controller;
  late GraphDataQueryController queryController;
  late MockGraphApi mockApi;

  setUpAll(() {
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
    registerFallbackValue(
      IRelation(
        key: 'dummy',
        in_: const frb.RecordStrings(table: 'dummy', key: 'in'),
        out: const frb.RecordStrings(table: 'dummy', key: 'out'),
        fields: IRelationFields(
          verb: 'link',
          layer: 'default',
          directionless: false,
          createdAt: 0,
          updatedAt: 0,
        ),
      ),
    );
    registerFallbackValue(SymmetricEntityPatch(
      id: const frb.RecordStrings(table: 'INode', key: 'dummy'),
      forward: const EntityPatch.node([]),
      reverse: const EntityPatch.node([]),
    ));
  });

  setUp(() {
    mockApi = MockGraphApi();
    when(() => mockApi.createNode(input: any(named: 'input')))
        .thenAnswer((_) async {});
    when(() => mockApi.createRelation(input: any(named: 'input')))
        .thenAnswer((_) async {});
    when(() => mockApi.createGraphStream())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockApi.undoCount()).thenAnswer((_) async => 0);
    when(() => mockApi.redoCount()).thenAnswer((_) async => 0);
    when(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation')))
        .thenAnswer((_) async {});

    queryController = GraphDataQueryController(mockApi);
    controller = CommandQueueProcessor(mockApi, queryController);

    when(() => mockApi.getGraphSnapshot()).thenAnswer(
      (_) async => GraphSnapshot(
        nodes: queryController.nodeLookup.values.map((n) => n.toRust()).toList(),
        relations: queryController.relationLookup.values.map((r) => r.toRust()).toList(),
        metadata: frb.MapData(
          mapName: '',
          viewportState: frb.ViewportState(
            xOffset: 0,
            yOffset: 0,
            zoomLevel: 1,
            activeView: '',
          ),
          displayMode: frb.DisplayMode.importance,
        ),
      ),
    );
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

    test('heading with children creates tree of nodes with relations', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Root\n\n- Child 1\n- Child 2',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(3));
    });

    test('nested headings create deep tree', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Level 1\n\n## Level 2\n\n### Level 3',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(3));
    });

    test('bullet items become children of preceding heading', () async {
      await pasteTextToCanvas(
        dataController: controller,
        text: '# Tasks\n\n- Item A\n- Item B',
        canvasPosition: const Offset(100, 100),
      );
      await controller.flush();
      expect(queryController.nodeLookup.length, equals(3));
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
    });
  });
}
