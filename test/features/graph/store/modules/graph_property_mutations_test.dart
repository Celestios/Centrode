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
      const GraphTheme(id: 'test', name: 'test');
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

  group('GraphPropertyMutations', () {
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

    test(
      'updateRelationStyle updates style, clears resolvedStyle, notifies updater, and triggers FFI mutate call',
      () async {
        final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
        final node2 = controller.createNode(
          UiNodes.info,
          const Offset(100, 100),
        );

        controller.createRelation(node1, node2);
        final relId = queryController.relations.first.id;

        final initialRel = queryController.relationLookup[relId]!;
        initialRel.resolvedStyle = const RelationStyle(
          bgColor: 0,
          strokeColor: 0,
          strokeWidth: 1,
          fontFamily: 'Roboto',
          fontSize: 12,
          shape: 'line',
          arrowType: 'none',
          arrowSize: 0,
          width: 0,
          height: 0,
          textColor: 0,
          shadowColor: 0,
          shadowBlur: 0,
          shadowOffsetX: 0,
          shadowOffsetY: 0,
          strategyType: 'default',
          strokePattern: 'solid',
          bodyStrategy: 'none',
        );

        final mockStyleUpdater = MockStyleUpdater();
        controller.styleUpdater = mockStyleUpdater;

        when(
          () => mockStyleUpdater.updateStyleForRelation(relId),
        ).thenAnswer((_) {});
        when(
          () => mockApi.applyEntityMutation(mutation: any(named: 'mutation')),
        ).thenAnswer((_) async {});

        final newStyle = const RelationStyle(
          bgColor: 0,
          strokeColor: 0,
          strokeWidth: 2,
          fontFamily: 'Roboto',
          fontSize: 12,
          shape: 'line',
          arrowType: 'none',
          arrowSize: 0,
          width: 0,
          height: 0,
          textColor: 0,
          shadowColor: 0,
          shadowBlur: 0,
          shadowOffsetX: 0,
          shadowOffsetY: 0,
          strategyType: 'default',
          strokePattern: 'dashed',
          bodyStrategy: 'none',
        );

        controller.updateRelationStyle(relId, newStyle);

        final updated = queryController.relationLookup[relId]!;
        expect(updated.style, newStyle);
        expect(updated.resolvedStyle, isNull);

        verify(() => mockStyleUpdater.updateStyleForRelation(relId)).called(1);

        await controller.syncEngine.processor.forceFlush();
        verify(
          () => mockApi.applyEntityMutation(mutation: any(named: 'mutation')),
        ).called(1);
      },
    );

    test(
      'updateRelationStyle rolls back to old style and triggers updater notification on FFI failure',
      () async {
        final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
        final node2 = controller.createNode(
          UiNodes.info,
          const Offset(100, 100),
        );

        controller.createRelation(node1, node2);
        final relId = queryController.relations.first.id;

        final initialStyle = const RelationStyle(
          bgColor: 0,
          strokeColor: 0,
          strokeWidth: 1,
          fontFamily: 'Roboto',
          fontSize: 12,
          shape: 'line',
          arrowType: 'none',
          arrowSize: 0,
          width: 0,
          height: 0,
          textColor: 0,
          shadowColor: 0,
          shadowBlur: 0,
          shadowOffsetX: 0,
          shadowOffsetY: 0,
          strategyType: 'default',
          strokePattern: 'solid',
          bodyStrategy: 'none',
        );

        final initialRel =
            queryController.relationLookup[relId]! as InfoUiRelation;
        initialRel.style = initialStyle;

        final mockStyleUpdater = MockStyleUpdater();
        controller.styleUpdater = mockStyleUpdater;

        when(
          () => mockStyleUpdater.updateStyleForRelation(relId),
        ).thenAnswer((_) {});
        when(
          () => mockApi.applyEntityMutation(mutation: any(named: 'mutation')),
        ).thenThrow(Exception('FFI mutation failed'));

        final newStyle = const RelationStyle(
          bgColor: 0,
          strokeColor: 0,
          strokeWidth: 2,
          fontFamily: 'Roboto',
          fontSize: 12,
          shape: 'line',
          arrowType: 'none',
          arrowSize: 0,
          width: 0,
          height: 0,
          textColor: 0,
          shadowColor: 0,
          shadowBlur: 0,
          shadowOffsetX: 0,
          shadowOffsetY: 0,
          strategyType: 'default',
          strokePattern: 'dashed',
          bodyStrategy: 'none',
        );

        // Perform styling update
        controller.updateRelationStyle(relId, newStyle);

        // Verify immediate optimistic update
        expect(queryController.relationLookup[relId]!.style, newStyle);

        // Expect a failure stream publication or rollback on flush
        try {
          await controller.syncEngine.processor.forceFlush();
          fail('Should throw the FFI exception during flush');
        } catch (e) {
          // Assert rollback occurred
          final rolledBack = queryController.relationLookup[relId]!;
          expect(rolledBack.style, initialStyle);
          // Verify style updater was notified twice (once for optimistic update, once for rollback)
          verify(
            () => mockStyleUpdater.updateStyleForRelation(relId),
          ).called(2);
        }
      },
    );
  });
}
