import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/store/graph_data_command.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}
class MockGraphDataCommand extends Mock implements GraphDataCommand {}

void main() {
  group('NodeRenderState', () {
    late MockGraphDataQuery mockQuery;
    late MockGraphDataCommand mockCommand;
    late NodeRenderState renderState;

    setUp(() {
      mockQuery = MockGraphDataQuery();
      mockCommand = MockGraphDataCommand();

      final dummyNode = InfoUiNode(id: RawUuid.fromString('node-1'), position: Offset.zero);
      when(() => mockQuery.nodeLookup).thenReturn({'node-1': dummyNode});
      when(() => mockQuery.relationLookup).thenReturn({});
      when(() => mockQuery.relations).thenReturn([]);
      when(() => mockQuery.onEntityUpdate).thenAnswer((_) => const Stream.empty());


      renderState = NodeRenderState(mockQuery, mockCommand);
    });


    test('initial state populates viewStates for nodes in lookup', () {
      expect(renderState.viewStates, hasLength(1));
      expect(renderState.activeLeftPanelNotifier.value, LeftPanelType.none);
      expect(renderState.activeInspectorTabNotifier.value, InspectorTab.appearance);
      expect(renderState.hoveredNodeNotifier.value, isNull);
    });


    test('selecting entity delegates to selection state', () {
      renderState.selectEntity('node-1');
      expect(renderState.selectedEntities, contains('node-1'));

      renderState.selectEntity(null);
      expect(renderState.selectedEntities, isEmpty);
    });

    test('entering and committing edit mode updates editor state', () {
      renderState.enterEditMode('node-1');
      expect(renderState.activeEditId, equals('node-1'));

      renderState.commitActiveEdit();
      expect(renderState.activeEditId, isNull);
    });
  });
}
