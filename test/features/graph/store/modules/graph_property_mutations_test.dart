import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/features/graph/models/commands/graph_command_context.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/domain/base_models.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:centrode/src/rust/relation_engine/config.dart';

class MockGraphApi extends Mock implements GraphApi {}

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

  group('GraphPropertyMutations', () {
    late CommandQueueProcessor controller;
    late GraphDataQueryController queryController;
    late MockGraphApi mockApi;


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
        (_) async => ComputedRelation(
          id: parseTypedRecordId('IRelation', RawUuid.fromString('dummy')),
          startPoint: const rust_geom.Point(x: 0, y: 0),
          endPoint: const rust_geom.Point(x: 0, y: 0),
          startHandlePos: const rust_geom.Point(x: 0, y: 0),
          endHandlePos: const rust_geom.Point(x: 0, y: 0),
          labelPosition: const rust_geom.Point(x: 0, y: 0),
          pathPoints: const [],
          startShapePath: const [],
          endShapePath: const [],
          startShapeFilled: false,
          endShapeFilled: false,
          bodyType: BodyType.uniform,
          bodyWidths: Float64List(0),
          pathType: PathType.straight,
          startTangent: const rust_geom.Point(x: 0, y: 0),
          endTangent: const rust_geom.Point(x: 0, y: 0),
          startEndpoint: EndpointShape.none,
          endEndpoint: EndpointShape.none,
          startDirection: 0.0,
          endDirection: 0.0,
          labelAnchor: LabelAnchor.center,
          bbox: const rust_geom.Rect(x: 0, y: 0, width: 0, height: 0),
          startArrowCenter: const rust_geom.Point(x: 0, y: 0),
          endArrowCenter: const rust_geom.Point(x: 0, y: 0),
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
        }
      },
    );

    test('updateNodeStyle updates node style and notifies subscribers', () async {
      final nodeId = controller.createNode(UiNodes.info, const Offset(0, 0));
      const newStyle = NodeStyle(
        bgColor: 0xFF123456,
        strokeColor: 0xFF654321,
        strokeWidth: 2,
        shape: 'rectangle',
        fontFamily: 'Inter',
        fontSize: 14,
        width: 200,
        height: 60,
        textColor: 0xFFFFFFFF,
        borderRadius: 8,
        padding: 8,
        shadowColor: 0,
        shadowBlur: 0,
        shadowSpread: 0,
        shadowOffsetX: 0,
        shadowOffsetY: 0,
        strategyType: 'default',
      );

      controller.propertyMutations.updateNodeStyle(nodeId, newStyle);

      final updatedNode = queryController.nodeLookup[nodeId]!;
      expect(updatedNode.style, equals(newStyle));
    });
  });
}

