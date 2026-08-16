import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/features/graph/presentation/drag_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/ui/canvas/layers/port_layer.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  group('Relation Tip Port Snap & Node Switching Bug Fix Tests', () {
    testWidgets(
      'PortLayer only marks port as snapped if snappedTargetNodeId matches active node',
      (tester) async {
        final nodeAId = RawUuid.v4();
        final nodeBId = RawUuid.v4();
        final relationId = RawUuid.v4();

        final nodeA = InfoUiNode(
          id: nodeAId,
          position: const Offset(0, 0),
          size: const Size(100, 100),
        );
        final nodeB = InfoUiNode(
          id: nodeBId,
          position: const Offset(300, 0),
          size: const Size(100, 100),
        );

        final vsA = NodeViewState(nodeA);
        final vsB = NodeViewState(nodeB);

        final Map<RawUuid, NodeViewState> nodeViewStates = {
          nodeAId: vsA,
          nodeBId: vsB,
        };

        const targetPortOnB = Port(
          side: PortSide.left,
          type: PortType.middle,
          index: 0,
          position: Offset(300, 50),
          edgePosition: Offset(300, 50),
        );

        // RelationTipDragging snapped to Node B's left port
        final interactionState = ValueNotifier<CanvasInteractionState>(
          RelationTipDragging(
            relationId: relationId,
            isStartTip: false,
            originalPosition: const Offset(100, 50),
            currentCursorPosition: const Offset(300, 50),
            snappedTargetNodeId: nodeBId,
            snappedTargetSide: PortSide.left,
            snappedPort: targetPortOnB,
          ),
        );

        final hoveredNodeNotifier = ValueNotifier<RawUuid?>(nodeAId);
        final hoveredPortNotifier = ValueNotifier<Port?>(null);
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

        // When Node A is the active node, PortPainter must NOT receive snappedTargetPort
        // because the snap belongs to Node B!
        final customPaintFinder = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PortPainter,
        );
        expect(customPaintFinder, findsOneWidget);

        final CustomPaint customPaintA = tester.widget(customPaintFinder);
        final PortPainter painterA = customPaintA.painter as PortPainter;
        expect(painterA.snappedTargetPort, isNull);

        // Switch active hovered node to Node B
        hoveredNodeNotifier.value = nodeBId;
        await tester.pump();

        final CustomPaint customPaintB = tester.widget(customPaintFinder);
        final PortPainter painterB = customPaintB.painter as PortPainter;
        expect(painterB.snappedTargetPort, equals(targetPortOnB));
      },
    );

    test('buildRelationLayoutPatches generates RelationPatch.endpoints when node endpoints change', () {
      final oldFromId = RawUuid.v4();
      final newFromId = RawUuid.v4();
      final toId = RawUuid.v4();

      final oldLayout = RelationLayout(
        fromSide: PortSide.right,
        toSide: PortSide.left,
        strategyType: 'bezier',
      );
      final newLayout = RelationLayout(
        fromSide: PortSide.top,
        toSide: PortSide.left,
        strategyType: 'bezier',
      );

      final (forward, reverse) = buildRelationLayoutPatches(
        oldLayout,
        newLayout,
        null,
        null,
        oldFromId: oldFromId,
        newFromId: newFromId,
        oldToId: toId,
        newToId: toId,
      );

      expect(forward.length, 2); // 1 layout patch + 1 endpoints patch
      expect(reverse.length, 2);
    });
  });
}
