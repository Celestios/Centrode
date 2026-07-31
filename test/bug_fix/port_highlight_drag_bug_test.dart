import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/presentation/drag_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/ui/canvas/layers/port_layer.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  testWidgets(
    'PortLayer suppresses hoveredPort highlighting during RelationDrawing on target node',
    (tester) async {
      final nodeId1 = RawUuid.v4();
      final nodeId2 = RawUuid.v4();

      final node1 = InfoUiNode(
        id: nodeId1,
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = InfoUiNode(
        id: nodeId2,
        position: const Offset(200, 0),
        size: const Size(100, 100),
      );

      final vs1 = NodeViewState(node1);
      final vs2 = NodeViewState(node2);

      final Map<RawUuid, NodeViewState> nodeViewStates = {
        nodeId1: vs1,
        nodeId2: vs2,
      };

      final hoveredNodeNotifier = ValueNotifier<RawUuid?>(null);
      final hoveredPortNotifier = ValueNotifier<Port?>(
        const Port(
          side: PortSide.top,
          type: PortType.middle,
          index: 0,
          position: Offset(50, 0),
          edgePosition: Offset(50, 0),
        ),
      );

      final interactionState = ValueNotifier<CanvasInteractionState>(
        RelationDrawing({nodeId1}, const Offset(50, 0)),
      );

      final dragState = DragState();

      await tester.pumpWidget(
        PortLayer(
          nodeViewStates: nodeViewStates,
          hoveredNodeNotifier: hoveredNodeNotifier,
          hoveredPortNotifier: hoveredPortNotifier,
          interactionState: interactionState,
          dragState: dragState,
        ),
      );

      // Hover over node 2
      hoveredNodeNotifier.value = nodeId2;
      await tester.pump();

      // Verify CustomPaint with PortPainter is built with hoveredPort: null during RelationDrawing
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PortPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final CustomPaint customPaint = tester.widget(customPaintFinder);
      final PortPainter painter = customPaint.painter as PortPainter;

      expect(painter.hoveredPort, isNull);

      // When returning to CanvasIdle, hoveredPort should be restored
      interactionState.value = const CanvasIdle();
      await tester.pump();

      final CustomPaint updatedCustomPaint = tester.widget(customPaintFinder);
      final PortPainter updatedPainter =
          updatedCustomPaint.painter as PortPainter;
      expect(updatedPainter.hoveredPort, equals(hoveredPortNotifier.value));
    },
  );
}
