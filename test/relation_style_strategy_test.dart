import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_layout_strategy.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

void main() {
  test('resolveTipHandles calculates handles correctly for long distance', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 50),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10), // dx distance between node centers: 200px
      size: const Size(100, 50),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(fromSide: 'Auto', toSide: 'Auto'),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    // Endpoints for Auto between right/left sides:
    // fromRight = (110, 35), toLeft = (210, 35)
    // Distance = 100px
    final (start, end) = RelationLayoutStrategy.resolveEndpoints(relation, fromVs, toVs);
    expect(start, const Offset(110, 35));
    expect(end, const Offset(210, 35));

    final (handleStart, handleEnd) = RelationLayoutStrategy.resolveTipHandles(relation, fromVs, toVs);
    // Since distance is 100 (> 40), it should offset by 16px along the direction (1, 0)
    expect(handleStart, const Offset(126, 35));
    expect(handleEnd, const Offset(194, 35));
  });

  test('resolveTipHandles calculates handles correctly for short distance', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 50),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(120, 10), // dx distance between node centers: 110px
      size: const Size(100, 50),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(fromSide: 'Auto', toSide: 'Auto'),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    // Endpoints for Auto between right/left sides:
    // fromRight = (110, 35), toLeft = (120, 35)
    // Distance = 10px (< 40px)
    final (start, end) = RelationLayoutStrategy.resolveEndpoints(relation, fromVs, toVs);
    expect(start, const Offset(110, 35));
    expect(end, const Offset(120, 35));

    final (handleStart, handleEnd) = RelationLayoutStrategy.resolveTipHandles(relation, fromVs, toVs);
    // Since distance is 10 (< 40), handles should be at 1/3 and 2/3 of the way
    expect(handleStart, Offset(110 + 10 / 3, 35));
    expect(handleEnd, Offset(110 + 20 / 3, 35));
  });

  test('resolveEndpoints dynamically resolves opposite port during drag override', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 50),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 50),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(fromSide: 'Auto', toSide: 'Auto'),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    // Normally (Auto, Auto), rightPort of from and leftPort of to are closest
    // fromRight = (110, 35), toLeft = (210, 35)

    // Now simulate dragging the start tip to the bottom of the target node (e.g. (260, 100))
    // Because the drag cursor is now very close to the bottom of the target node,
    // the end tip on 'to_1' should dynamically update from Left (210, 35) to Bottom (260, 60) to face it.
    final (start, end) = RelationLayoutStrategy.resolveEndpoints(
      relation,
      fromVs,
      toVs,
      overrideStart: const Offset(260, 100),
    );

    expect(start, const Offset(260, 100)); // Start is overridden to cursor
    expect(end, const Offset(260, 60)); // End dynamically snapped to Bottom port of target node!
  });
}
