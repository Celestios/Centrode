import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/models/commands/graph_command_context.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';

class MockStyleUpdater extends Mock implements GraphStyleUpdater {}

void main() {
  group('GraphPropertyMutations', () {
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
        expect(api.invocationLog.contains('applyEntityMutation'), isTrue);
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

