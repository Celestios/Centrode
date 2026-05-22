import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';

void main() {
  test('NodeViewState rightResizeHitbox offset shift check', () {
    final node = InfoUiNode(
      id: 'test-node-1',
      position: const Offset(100.0, 150.0),
      size: const Size(200.0, 100.0),
    );

    final viewState = NodeViewState(node);

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
}
