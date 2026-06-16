import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';

void main() {
  test('NodeViewState rightResizeHitbox offset shift check', () {
    final node = InfoUiNode(
      id: 'test-node-1',
      position: const Offset(100.0, 150.0),
      size: const Size(200.0, 100.0),
    );

    final viewState = NodeViewState(node);
    viewState.sizeNotifier.value = const Size(200.0, 100.0);

    // Verify properties
    expect(viewState.rect, const Rect.fromLTWH(100.0, 150.0, 200.0, 100.0));

    // Verify rightResizeHitbox is shifted down by 24.0 pixels from the top edge
    final expectedRightHitbox = Rect.fromLTRB(
      300.0 - AppConfig.interaction.resizeEdgeWidth, // right - edgeWidth
      150.0 + 24.0, // top + 24.0
      300.0, // right
      250.0, // bottom
    );

    expect(viewState.rightResizeHitbox, expectedRightHitbox);

    // Verify leftResizeHitbox is not shifted
    final expectedLeftHitbox = Rect.fromLTRB(
      100.0, // left
      150.0, // top
      100.0 + AppConfig.interaction.resizeEdgeWidth, // left + edgeWidth
      250.0, // bottom
    );

    expect(viewState.leftResizeHitbox, expectedLeftHitbox);
  });

  test('NodeLayoutStrategy and NodeStyleStrategy fromType resolution', () {
    // Test layout resolution
    expect(NodeLayoutStrategy.fromType('task'), isA<TaskNodeLayoutStrategy>());
    expect(NodeLayoutStrategy.fromType('info'), isA<InfoNodeLayoutStrategy>());

    final infoNode = InfoUiNode(id: 'info-1', position: Offset.zero);
    final taskNode = TaskUiNode(id: 'task-1', position: Offset.zero);

    expect(
      NodeLayoutStrategy.fromType(null, fallbackNode: infoNode),
      isA<InfoNodeLayoutStrategy>(),
    );
    expect(
      NodeLayoutStrategy.fromType(null, fallbackNode: taskNode),
      isA<TaskNodeLayoutStrategy>(),
    );

    // Test style resolution
    expect(NodeStyleStrategy.fromType('task'), isA<TaskNodeStyleStrategy>());
    expect(NodeStyleStrategy.fromType('info'), isA<InfoNodeStyleStrategy>());

    expect(
      NodeStyleStrategy.fromType(null, fallbackNode: infoNode),
      isA<InfoNodeStyleStrategy>(),
    );
    expect(
      NodeStyleStrategy.fromType(null, fallbackNode: taskNode),
      isA<TaskNodeStyleStrategy>(),
    );
  });

  test('NodeViewState getClosestPort finds the correct closest port', () {
    final node = InfoUiNode(
      id: 'test-node-1',
      position: const Offset(100.0, 100.0),
      size: const Size(100.0, 100.0),
    );
    final viewState = NodeViewState(node);
    viewState.sizeNotifier.value = const Size(100.0, 100.0);

    // Left port: (100.0, 150.0)
    // Right port: (200.0, 150.0)
    // Top port: (150.0, 100.0)
    // Bottom port: (150.0, 200.0)

    // Point near top port: (150.0, 90.0)
    final topClosest = viewState.getClosestPort(const Offset(150.0, 90.0));
    expect(topClosest.name, 'Top');
    expect(topClosest.position, const Offset(150.0, 100.0));

    // Point near left port: (95.0, 155.0)
    final leftClosest = viewState.getClosestPort(const Offset(95.0, 155.0));
    expect(leftClosest.name, 'Left');
    expect(leftClosest.position, const Offset(100.0, 150.0));
  });

  test('NodeViewState getClosestPortsBetween finds closest pair of ports', () {
    final node1 = InfoUiNode(
      id: 'test-node-1',
      position: const Offset(100.0, 100.0),
      size: const Size(100.0, 100.0),
    );
    final node2 = InfoUiNode(
      id: 'test-node-2',
      position: const Offset(300.0, 100.0), // directly to the right
      size: const Size(100.0, 100.0),
    );

    final vs1 = NodeViewState(node1);
    vs1.sizeNotifier.value = const Size(100.0, 100.0);
    final vs2 = NodeViewState(node2);
    vs2.sizeNotifier.value = const Size(100.0, 100.0);

    // Closest ports should be: vs1's Right (200.0, 150.0) and vs2's Left (300.0, 150.0)
    final closest = NodeViewState.getClosestPortsBetween(vs1, vs2);
    expect(closest.startName, 'Right');
    expect(closest.startPos, const Offset(200.0, 150.0));
    expect(closest.endName, 'Left');
    expect(closest.endPos, const Offset(300.0, 150.0));
  });
}
