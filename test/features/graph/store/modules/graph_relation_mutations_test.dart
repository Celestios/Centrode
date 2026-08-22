import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/presentation/theme_manager.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/features/graph/models/commands/graph_command_context.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/domain/base_models.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:centrode/src/rust/domain/routing.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'dart:typed_data';

class MockGraphApi extends Mock implements GraphApi {}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme =>
      const GraphTheme(id: 'test', name: 'test');
}

class MockStyleUpdater extends Mock implements GraphStyleUpdater {}

class FakeSymmetricEntityPatch extends Fake implements SymmetricEntityPatch {}

class FakeRelationEngineConfig extends Fake implements RelationEngineConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSymmetricEntityPatch());
    registerFallbackValue(FakeRelationEngineConfig());
    registerFallbackValue(
      parseTypedRecordId('INode', RawUuid.fromString('dummy')),
    );
    registerFallbackValue(
      Nodes.iNode(
        INode(
          id: parseTypedRecordId('INode', RawUuid.fromString('dummy')),
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
          attachments: const [],
          significance: 0,
          createdAt: 0,
          updatedAt: 0,
          lineCount: 1,
        ),
      ),
    );
    registerFallbackValue(
      IRelation(
        key: parseTypedRecordId('IRelation', RawUuid.fromString('dummy')),
        in_: parseTypedRecordId('INode', RawUuid.fromString('in')),
        out: parseTypedRecordId('INode', RawUuid.fromString('out')),
        fields: IRelationFields(
          verb: 'link',
          layer: 'default',
          direction: RelationDirection.forward,
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
          key: parseTypedRecordId('IRelation', RawUuid.fromString('dummy-rel')),
          in_: parseTypedRecordId('INode', RawUuid.fromString('n1')),
          out: parseTypedRecordId('TaskNode', RawUuid.fromString('n2')),
          fields: IRelationFields(
            verb: 'depends',
            direction: RelationDirection.forward,
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
        () => mockApi.updateNodeCachePositions(
          positions: any(named: 'positions'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.createRelation(input: any(named: 'input')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.createNode(input: any(named: 'input')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.deleteRelation(id: any(named: 'id')),
      ).thenAnswer((_) async {});
      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => mockApi.computeSingleRelation(
          config: any(named: 'config'),
          edgeId: any(named: 'edgeId'),
          fromNodeId: any(named: 'fromNodeId'),
          toNodeId: any(named: 'toNodeId'),
          fromSide: any(named: 'fromSide'),
          toSide: any(named: 'toSide'),
          routingMode: any(named: 'routingMode'),
          overrideStartX: any(named: 'overrideStartX'),
          overrideStartY: any(named: 'overrideStartY'),
          overrideEndX: any(named: 'overrideEndX'),
          overrideEndY: any(named: 'overrideEndY'),
        ),
      ).thenAnswer(
        (invocation) async => ComputedRelation(
          id: (invocation.namedArguments[#edgeId] as TypedRecordId?) ??
              parseTypedRecordId('IRelation', RawUuid.fromString('dummy')),
          startPoint: const Point(x: 0, y: 0),
          endPoint: const Point(x: 0, y: 0),
          startHandlePos: const Point(x: 0, y: 0),
          endHandlePos: const Point(x: 0, y: 0),
          labelPosition: const Point(x: 0, y: 0),
          pathPoints: const [],
          startShapePath: const [],
          endShapePath: const [],
          startShapeFilled: false,
          endShapeFilled: false,
          bodyType: BodyType.uniform,
          bodyWidths: Float64List(0),
          pathType: PathType.straight,
          startTangent: const Point(x: 0, y: 0),
          endTangent: const Point(x: 0, y: 0),
          startEndpoint: EndpointShape.none,
          endEndpoint: EndpointShape.none,
          startDirection: 0.0,
          endDirection: 0.0,
          labelAnchor: LabelAnchor.center,
          bbox: const rust_geom.Rect(x: 0, y: 0, width: 0, height: 0),
          startArrowCenter: const Point(x: 0, y: 0),
          endArrowCenter: const Point(x: 0, y: 0),
          startMargin: 0.0,
          endMargin: 0.0,
          dependsOnNodes: const [],
          controlPoints: const [],
          knots: Float64List(0),
          nudgeColors: const [],
          hitTestPoints: const [],
          composeActive: false,
        ),
      );
      when(
        () => mockApi.computeRelations(
          config: any(named: 'config'),
          relationIds: any(named: 'relationIds'),
        ),
      ).thenAnswer((_) async => []);
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
      when(() => mockApi.undoCount()).thenAnswer((_) async => 0);
      when(() => mockApi.redoCount()).thenAnswer((_) async => 0);

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
      verify(() => mockApi.deleteRelation(id: any(named: 'id'))).called(1);
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
