import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/features/graph/store/modules/graph_store.dart';
import 'package:centrode/features/graph/store/modules/layout_tick_interpolator.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';

void main() {
  group('LayoutTickInterpolator', () {
    late GraphStore store;
    late LayoutTickInterpolator interpolator;
    late RawUuid nodeAId;
    late RawUuid nodeBId;
    late RawUuid relId;

    setUp(() {
      store = GraphStore();
      interpolator = LayoutTickInterpolator(
        subStepsCount: 2,
        subStepDuration: const Duration(milliseconds: 10),
      );

      nodeAId = RawUuid.fromString('node-a');
      nodeBId = RawUuid.fromString('node-b');
      relId = RawUuid.fromString('rel-ab');

      final nodeA = InfoUiNode(
        id: nodeAId,
        position: const Offset(0, 0),
        size: const Size(100, 50),
      );
      final nodeB = InfoUiNode(
        id: nodeBId,
        position: const Offset(200, 200),
        size: const Size(100, 50),
      );

      final relation = InfoUiRelation(
        id: relId,
        fromNodeId: nodeAId,
        fromNodeTable: 'INode',
        toNodeId: nodeBId,
        toNodeTable: 'INode',
        verb: 'link',
      );

      store.nodeLookup[nodeAId] = nodeA;
      store.nodeLookup[nodeBId] = nodeB;
      store.relationLookup[relId] = relation;
    });

    test('interpolates node positions and applies port patches on convergence', () async {
      final movedEvents = <Set<RawUuid>>[];
      LayoutTickResult? convergedResult;

      final tick = LayoutTickResult(
        iteration: 1,
        energy: 0.1,
        converged: true,
        positionPatches: [
          LayoutPatch(
            id: parseTypedRecordId('INode', nodeAId),
            x: 50,
            y: 50,
          ),
        ],
        portPatches: [
          PortPatch(
            relationId: parseTypedRecordId('IRelation', relId),
            fromSide: PortSide.right,
            toSide: PortSide.left,
          ),
        ],
      );

      interpolator.processTick(
        tick: tick,
        store: store,
        onSubStep: (moved) => movedEvents.add(Set.from(moved)),
        onConverged: (result) => convergedResult = result,
      );

      // Wait for sub-steps to execute (2 sub-steps of 10ms = 20ms)
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(movedEvents.isNotEmpty, isTrue);
      expect(convergedResult, isNotNull);
      expect(convergedResult!.converged, isTrue);

      // Verify node final position
      final nodeA = store.nodeLookup[nodeAId]!;
      expect(nodeA.position.dx, equals(50));
      expect(nodeA.position.dy, equals(50));

      // Verify port patch was applied to the relation in store
      final relation = store.relationLookup[relId]!;
      expect(relation.resolvedLayout, isNotNull);
      expect(relation.resolvedLayout!.fromSide, equals(PortSide.right));
      expect(relation.resolvedLayout!.toSide, equals(PortSide.left));
    });

    test('cancel aborts ongoing interpolation loop', () async {
      final tick = LayoutTickResult(
        iteration: 1,
        energy: 5.0,
        converged: false,
        positionPatches: [
          LayoutPatch(
            id: parseTypedRecordId('INode', nodeAId),
            x: 100,
            y: 100,
          ),
        ],
        portPatches: [],
      );

      bool convergedCalled = false;
      interpolator.processTick(
        tick: tick,
        store: store,
        onSubStep: (_) {},
        onConverged: (_) => convergedCalled = true,
      );

      interpolator.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(convergedCalled, isFalse);
    });
  });
}
