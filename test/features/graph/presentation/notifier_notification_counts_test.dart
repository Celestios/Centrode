import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/presentation/editor_state.dart';
import 'package:mycelium/features/graph/presentation/selection_state.dart';
import 'package:mycelium/features/graph/presentation/drag_state.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/store/graph_data_command.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mocktail/mocktail.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}
class MockGraphDataCommand extends Mock implements GraphDataCommand {}

UiNode _makeNode(String id) => InfoUiNode(
  position: Offset.zero,
  id: id,
  size: const Size(100, 50),
);

void main() {
  late MockGraphDataQuery mockQuery;
  late MockGraphDataCommand mockCommand;
  final testNodes = {'node-1': _makeNode('node-1'), 'node-2': _makeNode('node-2')};

  setUp(() {
    mockQuery = MockGraphDataQuery();
    mockCommand = MockGraphDataCommand();
    when(() => mockQuery.nodeLookup).thenReturn(testNodes);
    when(() => mockQuery.relationLookup).thenReturn({});
    when(() => mockQuery.relations).thenReturn([]);
    when(() => mockQuery.onEntityUpdate).thenAnswer((_) => const Stream.empty());
  });

  group('NodeRenderState notification counts', () {
    test('selectEntity notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity('node-1');

      expect(notifyCount, 1, reason: 'selectEntity should forward notification from SelectionState');
      state.dispose();
    });

    test('selectEntities notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntities(['node-1', 'node-2']);

      expect(notifyCount, 1);
      state.dispose();
    });

    test('enterEditMode notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.enterEditMode('test-id');

      expect(notifyCount, 1);
      state.dispose();
    });

    test('cancelActiveEdit notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      state.enterEditMode('test-id');
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.cancelActiveEdit();

      expect(notifyCount, 1);
      state.dispose();
    });

    test('setNodeDragging does not notify (drag uses MovementNotifier)', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setNodeDragging('test-id', true);

      expect(notifyCount, 0);
      state.dispose();
    });
  });

  group('EditorState notification counts', () {
    final viewStates = <String, NodeViewState>{};

    test('enterEditMode notifies exactly once', () {
      final state = EditorState(mockQuery, viewStates);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.enterEditMode('test-id');

      expect(notifyCount, 1);
      state.dispose();
    });

    test('cancelActiveEdit notifies exactly once', () {
      final state = EditorState(mockQuery, viewStates);
      state.enterEditMode('test-id');
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.cancelActiveEdit();

      expect(notifyCount, 1);
      state.dispose();
    });

    test('showFloatingToolbar notifies exactly once', () {
      final state = EditorState(mockQuery, viewStates);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.showFloatingToolbar('node-1');

      expect(notifyCount, 1);
      state.dispose();
    });

    test('showFloatingToolbar same node does not re-notify', () {
      final state = EditorState(mockQuery, viewStates);
      state.showFloatingToolbar('node-1');
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.showFloatingToolbar('node-1');

      expect(notifyCount, 0);
      state.dispose();
    });
  });

  group('SelectionState notification counts', () {
    test('selectEntity notifies exactly once', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity('node-1');

      expect(notifyCount, 1, reason: 'selectEntity should notify once when selecting a valid entity');
    });

    test('selectEntity null with empty selection does not notify', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity(null);

      expect(notifyCount, 0, reason: 'selectEntity(null) on empty selection should not notify');
    });

    test('selectEntities notifies exactly once', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntities(['node-1', 'node-2']);

      expect(notifyCount, 1);
    });
  });

  group('DragState notification counts', () {
    test('setNodeDragging notifies exactly once', () {
      final state = DragState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setNodeDragging('test-id', true);

      expect(notifyCount, 1);
    });
  });
}
