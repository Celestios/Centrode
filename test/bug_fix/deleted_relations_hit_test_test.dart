import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/engine/hit_test_resolver.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;

class MockGraphApi extends Mock implements GraphApi {}
class FakeIRelation extends Fake implements IRelation {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeIRelation());
    registerFallbackValue(
      parseTypedRecordId('INode', RawUuid.fromString('dummy')),
    );
    registerFallbackValue(
      parseTypedRecordId('IRelation', RawUuid.fromString('dummy')),
    );
    registerFallbackValue(
      Nodes.iNode(
        INode(
          id: parseTypedRecordId('INode', RawUuid.fromString('dummy')),
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
  });

  test('Deleting a node optimistic teardown purges connected relations and prevents ghost hit testing', () async {
    final mockApi = MockGraphApi();
    when(() => mockApi.createNode(input: any(named: 'input'))).thenAnswer((_) async {});
    when(() => mockApi.createRelation(input: any(named: 'input'))).thenAnswer((_) async {});
    when(() => mockApi.deleteNodeEntry(id: any(named: 'id'))).thenAnswer((_) async {});
    when(() => mockApi.deleteRelation(id: any(named: 'id'))).thenAnswer((_) async {});
    when(() => mockApi.updateNodeCachePositions(positions: any(named: 'positions'))).thenAnswer((_) async {});

    final queryController = GraphDataQueryController(mockApi);
    final processor = CommandQueueProcessor(mockApi, queryController);
    final renderState = NodeRenderState(queryController, processor);
    final viewportController = ViewportController(queryController);

    // Create 2 nodes
    final n1Id = processor.nodeMutations.createNode(
      UiNodes.info,
      const Offset(100, 100),
    );
    final n2Id = processor.nodeMutations.createNode(
      UiNodes.info,
      const Offset(300, 300),
    );

    // Create relation between n1 and n2
    final createdRel = processor.relationMutations.createRelation(n1Id, n2Id);
    expect(createdRel, isNotNull);
    final relId = createdRel!.id;

    // Verify initial store state
    expect(queryController.nodeLookup.containsKey(n1Id), isTrue);
    expect(queryController.nodeLookup.containsKey(n2Id), isTrue);
    expect(queryController.relationLookup.containsKey(relId), isTrue);

    // Delete node 1
    await processor.deleteNode(n1Id);

    // Assert optimistic teardown of node 1 AND connected relation
    expect(queryController.nodeLookup.containsKey(n1Id), isFalse);
    expect(queryController.relationLookup.containsKey(relId), isFalse, reason: 'Connected relation should be optimistically deleted');

    // Perform hit test at relation midpoint (200, 200)
    final environment = CanvasInteractionEnvironment(
      queryController: queryController,
      commandProcessor: processor,
      renderState: renderState,
      viewportController: viewportController,
      getScale: () => 1.0,
    );

    const hitResolver = HitTestResolver();
    final hitResult = hitResolver.resolve(
      const Offset(200, 200),
      environment,
      false,
    );

    expect(hitResult.type, equals(HitTestType.none), reason: 'Deleted relation must not trigger hit testing');
  });
}
