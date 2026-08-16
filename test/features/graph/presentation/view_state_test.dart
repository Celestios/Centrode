import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  test('NodeViewState rightResizeHitbox extends full height without metadata and shifts with metadata', () {
    final nodeWithoutMeta = InfoUiNode(
      id: RawUuid.fromString('test-node-1'),
      position: const Offset(100.0, 150.0),
      size: const Size(200.0, 100.0),
    );

    final viewState1 = NodeViewState(nodeWithoutMeta);
    viewState1.sizeNotifier.value = const Size(200.0, 100.0);

    // Verify rightResizeHitbox extends full height from top (150.0) when no metadata exists
    final expectedFullHeightRightHitbox = Rect.fromLTRB(
      300.0 - AppConfig.interaction.resizeEdgeWidth, // right - edgeWidth
      150.0, // top (0 offset)
      300.0, // right
      250.0, // bottom
    );
    expect(viewState1.rightResizeHitbox, expectedFullHeightRightHitbox);

    // Node with comments has metadata sphere
    final nodeWithMeta = InfoUiNode(
      id: RawUuid.fromString('test-node-2'),
      position: const Offset(100.0, 150.0),
      size: const Size(200.0, 100.0),
      comments: const [Comment(text: 'test comment', createdAt: 0)],
    );

    final viewState2 = NodeViewState(nodeWithMeta);
    viewState2.sizeNotifier.value = const Size(200.0, 100.0);

    // Verify rightResizeHitbox is shifted down by 24.0 pixels when metadata exists
    final expectedShiftedRightHitbox = Rect.fromLTRB(
      300.0 - AppConfig.interaction.resizeEdgeWidth,
      150.0 + 24.0, // top + 24.0
      300.0,
      250.0,
    );
    expect(viewState2.rightResizeHitbox, expectedShiftedRightHitbox);
  });

  test('NodeViewState getClosestPort finds the correct closest port', () {
    final node = InfoUiNode(
      id: RawUuid.fromString('test-node-1'),
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
    expect(topClosest.side.name, 'top');
    expect(topClosest.position, const Offset(150.0, 100.0));

    // Point near left port: (95.0, 155.0)
    final leftClosest = viewState.getClosestPort(const Offset(95.0, 155.0));
    expect(leftClosest.side.name, 'left');
    expect(leftClosest.position, const Offset(100.0, 150.0));
  });

  test('NodeViewState getClosestPortsBetween finds closest pair of ports', () {
    final node1 = InfoUiNode(
      id: RawUuid.fromString('test-node-1'),
      position: const Offset(100.0, 100.0),
      size: const Size(100.0, 100.0),
    );
    final node2 = InfoUiNode(
      id: RawUuid.fromString('test-node-2'),
      position: const Offset(300.0, 100.0), // directly to the right
      size: const Size(100.0, 100.0),
    );

    final vs1 = NodeViewState(node1);
    vs1.sizeNotifier.value = const Size(100.0, 100.0);
    final vs2 = NodeViewState(node2);
    vs2.sizeNotifier.value = const Size(100.0, 100.0);

    // Closest ports should be: vs1's Right (200.0, 150.0) and vs2's Left (300.0, 150.0)
    final closest = NodeViewState.getClosestPortsBetween(vs1, vs2);
    expect(closest.startSide.name, 'right');
    expect(closest.startPos, const Offset(200.0, 150.0));
    expect(closest.endSide.name, 'left');
    expect(closest.endPos, const Offset(300.0, 150.0));
  });

  test('NodeViewState scales currentScale and ports for FrameUiNode based on size', () {
    final frameNode = FrameUiNode(
      id: RawUuid.fromString('test-frame-1'),
      title: 'Test Frame',
      position: const Offset(0.0, 0.0),
      size: const Size(400.0, 300.0),
    );

    final vs = NodeViewState(frameNode);
    expect(vs.currentScale, 1.0);

    // Initial base size ports check
    final initialPorts = vs.ports;
    final initialTopPort = initialPorts.getPortBySide(PortSide.top)!;
    expect(initialTopPort.position.dy, -AppConfig.port.edgeOffset * 1.0);

    // Scale frame to 2x (800x600)
    vs.sizeNotifier.value = const Size(800.0, 600.0);
    expect(vs.currentScale, 2.0);

    final scaledPorts = vs.ports;
    final scaledTopPort = scaledPorts.getPortBySide(PortSide.top)!;
    expect(scaledTopPort.position.dy, -AppConfig.port.edgeOffset * 2.0);
  });
}
