import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/store/graph_data_query_controller.dart';
import 'package:mycelium/features/graph/store/command_queue_processor.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/features/graph/store/graph_api.dart';
import 'package:mycelium/features/graph/models/commands/graph_command_context.dart';
import 'package:mycelium/features/graph/models/commands/patch_helpers.dart';
import 'package:mycelium/src/rust/domain/base_models.dart';
import 'package:mycelium/src/rust/domain/snapshot.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class MockGraphApi extends Mock implements GraphApi {}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme =>
      const GraphTheme(id: RawUuid.fromString('test'), name: 'test');
}

class MockStyleUpdater extends Mock implements GraphStyleUpdater {}

class FakeSymmetricEntityPatch extends Fake implements SymmetricEntityPatch {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSymmetricEntityPatch());
    registerFallbackValue(
      Nodes.iNode(
        INode(
          id: parseTypedRecordId('INode', 'dummy'),
          content: ContentFactory.empty(),
          layer: 'default',
          position: const Coordinates(x: 0, y: 0),
          size: const Size(width: 10, height: 10),
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
        key: parseTypedRecordId('IRelation', 'dummy'),
        in_: parseTypedRecordId('INode', 'in'),
        out: parseTypedRecordId('INode', 'out'),
        fields: IRelationFields(
          verb: 'link',
          layer: 'default',
          directionless: false,
          createdAt: 0,
          updatedAt: 0,
        ),
      ),
    );
  });

  group('GraphRelationMutations', () {
    late CommandQueueProcessor controller;
    late GraphDataQueryController queryController;
    late MockGraphApi mockApi;

    setUpAll(() {
      registerFallbackValue(
        IRelation(
          key: parseTypedRecordId('IRelation', 'dummy-rel'),
          in_: parseTypedRecordId('INode', 'n1'),
          out: parseTypedRecordId('TaskNode', 'n2'),
          fields: IRelationFields(
            verb: 'depends',
            directionless: false,
            layer: 'default',
            createdAt: 0,
            updatedAt: 0,
          ),
        ),
      );
    });

    setUp(() {
      mockApi = MockGraphApi();

      when(
        () => mockApi.createRelation(input: any(named: 'input')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.createNode(input: any(named: 'input')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.deleteRelation(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot()).thenAnswer(
        (_) async => GraphSnapshot(
          nodes: [],
          relations: [],
          metadata: MapData(
            mapName: '',
            viewportState: ViewportState(
              xOffset: 0,
              yOffset: 0,
              zoomLevel: 1,
              activeView: '',
            ),
            displayMode: DisplayMode.importance,
          ),
        ),
      );

      queryController = GraphDataQueryController(mockApi);
      controller = CommandQueueProcessor(mockApi, queryController);
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
      verify(
        () => mockApi.createRelation(input: any(named: 'input')),
      ).called(1);
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
      verify(
        () => mockApi.deleteRelation(id: any(named: 'id')),
      ).called(1);
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

        when(
          () => mockApi.applyEntityMutation(mutation: any(named: 'mutation')),
        ).thenAnswer((_) async {});

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
        verify(
          () => mockApi.applyEntityMutation(mutation: any(named: 'mutation')),
        ).called(1);
      },
    );
  });
}
