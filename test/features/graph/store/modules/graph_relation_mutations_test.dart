import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/relations.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/features/graph/models/content_builder.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockAppHandle extends Mock implements AppHandle {}
class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme => const GraphTheme(id: 'test', name: 'test');
}

class FakeSymmetricEntityPatch extends Fake implements SymmetricEntityPatch {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSymmetricEntityPatch());
    registerFallbackValue(Nodes.iNode(INode(
      key: 'dummy',
      fields: INodeFields(
        content: ContentFactory.empty(),
        layer: 'default',
        position: frb.Coordinates(x: 0, y: 0),
        size: frb.Size(width: 10, height: 10),
        expandable: false,
        isExpanded: false,
        locked: false,
        tags: [],
        aliases: [],
        comments: [],
        significance: 0,
        createdAt: 0,
        updatedAt: 0,
        lineCount: 1,
      ),
    )));
    registerFallbackValue(IRelation(
      key: 'dummy',
      in_: const frb.RecordStrings(table: 'dummy', key: 'in'),
      out: const frb.RecordStrings(table: 'dummy', key: 'out'),
      fields: IRelationFields(
        verb: 'link',
        layer: 'default',
        directionless: false,
        createdAt: 0,
        updatedAt: 0,
      )
    ));
  });

  group('GraphRelationMutations', () {
    late GraphDataController controller;
    late MockAppHandle mockApi;
    late MockThemeController mockThemeController;

    setUpAll(() {
      registerFallbackValue(IRelation(
        key: 'dummy-rel',
        in_: const frb.RecordStrings(table: 'INode', key: 'n1'),
        out: const frb.RecordStrings(table: 'TaskNode', key: 'n2'),
        fields: IRelationFields(
          verb: 'depends',
          directionless: false,
          layer: 'default',
          createdAt: 0,
          updatedAt: 0,
        ),
      ));
    });

    setUp(() {
      mockApi = MockAppHandle();
      mockThemeController = MockThemeController();

      when(() => mockApi.createRelation(input: any(named: 'input')))
          .thenAnswer((_) async {});
      when(() => mockApi.createNode(input: any(named: 'input')))
          .thenAnswer((_) async {});
      when(() => mockApi.deleteRelation(table: any(named: 'table'), key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockApi.createGraphStream())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot())
          .thenAnswer((_) async => (<INode>[], <TaskNode>[], <InterNode>[], <IRelation>[], const frb.MapData(
            mapName: '',
            viewportState: frb.ViewportState(xOffset: 0, yOffset: 0, zoomLevel: 1, activeView: ''),
            displayMode: frb.DisplayMode.importance,
          )));

      controller = GraphDataController(mockApi);
    });

    tearDown(() {
      controller.dispose();
    });

    test('createRelation inserts into store', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.task, const Offset(100, 100));

      controller.createRelation(node1, node2, fromSide: 'right', toSide: 'left');

      expect(controller.relations.length, 1);
      final rel = controller.relations.first;
      expect(rel.fromNodeId, node1);
      expect(rel.toNodeId, node2);
      expect(rel.layout?.fromSide, 'right');
      expect(rel.layout?.toSide, 'left');

      await controller.syncEngine.processor.forceFlush();
      verify(() => mockApi.createRelation(input: any(named: 'input'))).called(1);
    });

    test('deleteRelation removes from store', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.info, const Offset(100, 100));

      controller.createRelation(node1, node2);
      expect(controller.relations.length, 1);
      
      final relId = controller.relations.first.id;

      await controller.deleteRelation(relId);

      expect(controller.relations.isEmpty, isTrue);

      await controller.syncEngine.processor.forceFlush();
      verify(() => mockApi.deleteRelation(table: 'IRelation', key: relId)).called(1);
    });

    test('updateRelationLayout updates layout and triggers FFI mutate call', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.info, const Offset(100, 100));
      final node3 = controller.createNode(UiNodes.info, const Offset(200, 200));

      controller.createRelation(node1, node2);
      final relId = controller.relations.first.id;

      when(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation')))
          .thenAnswer((_) async {});

      controller.updateRelationLayout(
        relId,
        fromNodeId: node1,
        toNodeId: node3,
        fromSide: 'Top',
        toSide: 'Bottom',
        strategyType: 'bezier',
      );

      final updated = controller.store.relationLookup[relId]!;
      expect(updated.fromNodeId, node1);
      expect(updated.toNodeId, node3);
      expect(updated.layout?.fromSide, 'Top');
      expect(updated.layout?.toSide, 'Bottom');
      expect(updated.layout?.strategyType, 'bezier');

      await controller.syncEngine.processor.forceFlush();
      verify(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation'))).called(1);
    });
  });
}
