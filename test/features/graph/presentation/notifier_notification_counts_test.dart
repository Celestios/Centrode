import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/presentation/editor_state.dart';
import 'package:centrode/features/graph/presentation/selection_state.dart';
import 'package:centrode/features/graph/presentation/drag_state.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}

class MockGraphDataCommand extends Mock implements GraphDataCommand {}

UiNode _makeNode(RawUuid id) =>
    InfoUiNode(position: Offset.zero, id: id, size: const Size(100, 50));

final _node1 = RawUuid.fromString('node-1');
final _node2 = RawUuid.fromString('node-2');
final _testId = RawUuid.fromString('test-id');

void main() {
  late MockGraphDataQuery mockQuery;
  late MockGraphDataCommand mockCommand;
  final testNodes = {_node1: _makeNode(_node1), _node2: _makeNode(_node2)};

  setUp(() {
    mockQuery = MockGraphDataQuery();
    mockCommand = MockGraphDataCommand();
    when(() => mockQuery.nodeLookup).thenReturn(testNodes);
    when(() => mockQuery.relationLookup).thenReturn({});
    when(() => mockQuery.relations).thenReturn([]);
    when(
      () => mockQuery.onEntityUpdate,
    ).thenAnswer((_) => const Stream.empty());
  });

  group('NodeRenderState notification counts', () {
    test('selectEntity notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity(_node1);

      expect(
        notifyCount,
        1,
        reason: 'selectEntity should forward notification from SelectionState',
      );
      state.dispose();
    });

    test('selectEntities notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntities([_node1, _node2]);

      expect(notifyCount, 1);
      state.dispose();
    });

    test('enterEditMode notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.enterEditMode(_testId);

      expect(notifyCount, 1);
      state.dispose();
    });

    test('cancelActiveEdit notifies exactly once', () {
      final state = NodeRenderState(mockQuery, mockCommand);
      state.enterEditMode(_testId);
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

      state.setNodeDragging(_testId, true);

      expect(notifyCount, 0);
      state.dispose();
    });
  });

  group('EditorState notification counts', () {
    final viewStates = <RawUuid, NodeViewState>{};

    test('enterEditMode notifies exactly once', () {
      final state = EditorState(mockQuery, viewStates);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.enterEditMode(_testId);

      expect(notifyCount, 1);
      state.dispose();
    });

    test('cancelActiveEdit notifies exactly once', () {
      final state = EditorState(mockQuery, viewStates);
      state.enterEditMode(_testId);
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

      state.showFloatingToolbar(_node1);

      expect(notifyCount, 1);
      state.dispose();
    });

    test('showFloatingToolbar same node does not re-notify', () {
      final state = EditorState(mockQuery, viewStates);
      state.showFloatingToolbar(_node1);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.showFloatingToolbar(_node1);

      expect(notifyCount, 0);
      state.dispose();
    });
  });

  group('SelectionState notification counts', () {
    test('selectEntity notifies exactly once', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity(_node1);

      expect(
        notifyCount,
        1,
        reason: 'selectEntity should notify once when selecting a valid entity',
      );
    });

    test('selectEntity null with empty selection does not notify', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntity(null);

      expect(
        notifyCount,
        0,
        reason: 'selectEntity(null) on empty selection should not notify',
      );
    });

    test('selectEntities notifies exactly once', () {
      final state = SelectionState(mockQuery, mockCommand);
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.selectEntities([_node1, _node2]);

      expect(notifyCount, 1);
    });
  });

  group('DragState notification counts', () {
    test('setNodeDragging notifies exactly once', () {
      final state = DragState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setNodeDragging(_testId, true);

      expect(notifyCount, 1);
    });
  });
}
