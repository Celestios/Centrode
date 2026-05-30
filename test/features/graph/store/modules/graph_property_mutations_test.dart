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
import 'package:mycelium/src/rust/domain/styles.dart';

class MockAppHandle extends Mock implements AppHandle {}
class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme => const GraphTheme(id: 'test', name: 'test');
}
class MockStyleUpdater extends Mock implements GraphStyleUpdater {}

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

  group('GraphPropertyMutations', () {
    late GraphDataController controller;
    late MockAppHandle mockApi;

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

    test('updateRelationStyle updates style, clears resolvedStyle, notifies updater, and triggers FFI mutate call', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.info, const Offset(100, 100));

      controller.createRelation(node1, node2);
      final relId = controller.relations.first.id;

      final initialRel = controller.store.relationLookup[relId]!;
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
      );

      final mockStyleUpdater = MockStyleUpdater();
      controller.styleUpdater = mockStyleUpdater;
      
      when(() => mockStyleUpdater.updateStyleForRelation(relId)).thenAnswer((_) {});
      when(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation')))
          .thenAnswer((_) async {});

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
      );

      controller.updateRelationStyle(relId, newStyle);

      final updated = controller.store.relationLookup[relId]!;
      expect(updated.style, newStyle);
      expect(updated.resolvedStyle, isNull);

      verify(() => mockStyleUpdater.updateStyleForRelation(relId)).called(1);

      await controller.syncEngine.processor.forceFlush();
      verify(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation'))).called(1);
    });

    test('updateRelationStyle rolls back to old style and triggers updater notification on FFI failure', () async {
      final node1 = controller.createNode(UiNodes.info, const Offset(0, 0));
      final node2 = controller.createNode(UiNodes.info, const Offset(100, 100));

      controller.createRelation(node1, node2);
      final relId = controller.relations.first.id;

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
      );

      final initialRel = controller.store.relationLookup[relId]! as InfoUiRelation;
      initialRel.style = initialStyle;

      final mockStyleUpdater = MockStyleUpdater();
      controller.styleUpdater = mockStyleUpdater;
      
      when(() => mockStyleUpdater.updateStyleForRelation(relId)).thenAnswer((_) {});
      when(() => mockApi.applyEntityMutation(mutation: any(named: 'mutation')))
          .thenThrow(Exception('FFI mutation failed'));

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
      );

      // Perform styling update
      controller.updateRelationStyle(relId, newStyle);

      // Verify immediate optimistic update
      expect(controller.store.relationLookup[relId]!.style, newStyle);

      // Expect a failure stream publication or rollback on flush
      try {
        await controller.syncEngine.processor.forceFlush();
        fail('Should throw the FFI exception during flush');
      } catch (e) {
        // Assert rollback occurred
        final rolledBack = controller.store.relationLookup[relId]!;
        expect(rolledBack.style, initialStyle);
        // Verify style updater was notified twice (once for optimistic update, once for rollback)
        verify(() => mockStyleUpdater.updateStyleForRelation(relId)).called(2);
      }
    });
  });
}
