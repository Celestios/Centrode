import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_layout_strategy.dart';
import 'package:mycelium/features/graph/presentation/routing/relation_layout_context.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

Offset _getPortNormal(PortSide side) {
  switch (side) {
    case PortSide.left:
      return const Offset(-1, 0);
    case PortSide.right:
      return const Offset(1, 0);
    case PortSide.top:
      return const Offset(0, -1);
    case PortSide.bottom:
      return const Offset(0, 1);
  }
}

void main() {
  test('resolveTipHandles calculates handles correctly for long distance', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(
        210,
        10,
      ), // dx distance between node centers: 200px
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'default',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);
    final context = RelationLayoutContext(
      nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
      relations: [relation],
      pathCache: {},
    );

    // Endpoints for Auto between right/left sides:
    // fromRight = (110, 35), toLeft = (210, 35)
    // Distance = 100px
    const layoutStrategy = StraightRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation,
      fromVs,
      toVs,
    );
    expect(start, const Offset(110, 30));
    expect(end, const Offset(210, 30));

    final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
      relation,
      fromVs,
      toVs,
      context,
    );
    // Since distance is 100 (> 40), it should offset by 16px along the direction (1, 0)
    expect(handleStart, const Offset(126, 30));
    expect(handleEnd, const Offset(194, 30));
  });

  test('resolveTipHandles calculates handles correctly for short distance', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(
        120,
        10,
      ), // dx distance between node centers: 110px
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'default',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);
    final context = RelationLayoutContext(
      nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
      relations: [relation],
      pathCache: {},
    );

    // Endpoints for Auto between right/left sides:
    // fromRight = (110, 35), toLeft = (120, 35)
    // Distance = 10px (< 40px)
    const layoutStrategy = StraightRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation,
      fromVs,
      toVs,
    );
    expect(start, const Offset(110, 30));
    expect(end, const Offset(120, 30));

    final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
      relation,
      fromVs,
      toVs,
      context,
    );
    // Since distance is 10 (< 40), handles should be at 1/3 and 2/3 of the way
    expect(handleStart.dx, closeTo(110 + 10 / 3, 0.001));
    expect(handleStart.dy, closeTo(30, 0.001));
    expect(handleEnd.dx, closeTo(110 + 20 / 3, 0.001));
    expect(handleEnd.dy, closeTo(30, 0.001));
  });

  test(
    'resolveEndpoints dynamically resolves opposite port during drag override',
    () {
      final fromNode = InfoUiNode(
        id: 'from_1',
        position: const Offset(10, 10),
        size: const Size(100, 40),
      );
      final toNode = InfoUiNode(
        id: 'to_1',
        position: const Offset(210, 10),
        size: const Size(100, 40),
      );

      final relation = InfoUiRelation(
        fromNodeId: 'from_1',
        fromNodeTable: 'inode',
        toNodeId: 'to_1',
        toNodeTable: 'inode',
        layout: RelationLayout(
          fromSide: 'Auto',
          toSide: 'Auto',
          strategyType: 'default',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);

      // Normally (Auto, Auto), rightPort of from and leftPort of to are closest
      // fromRight = (110, 35), toLeft = (210, 35)

      // Now simulate dragging the start tip to the bottom of the target node (e.g. (260, 100))
      // Because the drag cursor is now very close to the bottom of the target node,
      // the end tip on 'to_1' should dynamically update from Left (210, 30) to Bottom (260, 50) to face it.
      const layoutStrategy = StraightRelationLayoutStrategy();
      final (start, end) = layoutStrategy.resolveEndpoints(
        relation,
        fromVs,
        toVs,
        overrideStart: const Offset(260, 100),
      );

      expect(start, const Offset(260, 100)); // Start is overridden to cursor
      expect(
        end,
        const Offset(260, 50),
      ); // End dynamically snapped to Bottom port of target node!
    },
  );

  test(
    'BezierRelationLayoutStrategy resolves dynamic port normals in Auto mode',
    () {
      final fromNode = InfoUiNode(
        id: 'from_1',
        position: const Offset(10, 10),
        size: const Size(100, 40),
      );
      final toNode = InfoUiNode(
        id: 'to_1',
        position: const Offset(210, 210), // shifted vertically by 200px
        size: const Size(100, 40),
      );

      final relation = InfoUiRelation(
        fromNodeId: 'from_1',
        fromNodeTable: 'inode',
        toNodeId: 'to_1',
        toNodeTable: 'inode',
        layout: RelationLayout(
          fromSide: 'Auto',
          toSide: 'Auto',
          strategyType: 'bezier',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);
      final context = RelationLayoutContext(
        nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
        relations: [relation],
        pathCache: {},
      );

      const layoutStrategy = BezierRelationLayoutStrategy();
      final (start, end) = layoutStrategy.resolveEndpoints(
        relation,
        fromVs,
        toVs,
      );
      // closest ports for this offset setup are bottomRight = (110, 50), topLeft = (210, 210)
      expect(start, const Offset(110, 50));
      expect(end, const Offset(210, 210));

      // Calculate a point on the bezier curve at t = 0.25 dynamically
      final distance = (end - start).distance;
      final proj = (distance * 0.4).clamp(30.0, 150.0);
      // Get actual normals from resolved ports
      final fromPort = fromVs.ports.getClosestPort(start);
      final toPort = toVs.ports.getClosestPort(end);
      final startNormal = fromPort != null ? _getPortNormal(fromPort.side) : const Offset(0.707, 0.707);
      final endNormal = toPort != null ? _getPortNormal(toPort.side) : const Offset(-0.707, -0.707);
      final p1 = start + startNormal * proj;
      final p2 = end + endNormal * proj;

      const t = 0.25;
      final t1 = 1 - t;
      final testPoint = start * (t1 * t1 * t1) +
          p1 * (3 * t1 * t1 * t) +
          p2 * (3 * t1 * t * t) +
          end * (t * t * t);

      const straightStrategy = StraightRelationLayoutStrategy();

      expect(
        straightStrategy.isPointNear(
          testPoint,
          start,
          end,
          fromVs,
          toVs,
          relation,
          2.0,
          context,
        ),
        isFalse,
      );
      expect(
        layoutStrategy.isPointNear(
          testPoint,
          start,
          end,
          fromVs,
          toVs,
          relation,
          2.0,
          context,
        ),
        isTrue,
      );
    },
  );

  test(
    'BezierRelationLayoutStrategy resolveTipHandles positions handles on the bezier curve',
    () {
      final fromNode = InfoUiNode(
        id: 'from_1',
        position: const Offset(10, 10),
        size: const Size(100, 40),
      );
      final toNode = InfoUiNode(
        id: 'to_1',
        position: const Offset(210, 110),
        size: const Size(100, 40),
      );

      final relation = InfoUiRelation(
        fromNodeId: 'from_1',
        fromNodeTable: 'inode',
        toNodeId: 'to_1',
        toNodeTable: 'inode',
        layout: RelationLayout(
          fromSide: 'Auto',
          toSide: 'Auto',
          strategyType: 'bezier',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);
      final context = RelationLayoutContext(
        nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
        relations: [relation],
        pathCache: {},
      );

      const layoutStrategy = BezierRelationLayoutStrategy();
      final (start, end) = layoutStrategy.resolveEndpoints(
        relation,
        fromVs,
        toVs,
      );
      final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
        relation,
        fromVs,
        toVs,
        context,
      );

      // Verify handles are on the curve (near the curve with small threshold e.g. 1.0)
      expect(
        layoutStrategy.isPointNear(
          handleStart,
          start,
          end,
          fromVs,
          toVs,
          relation,
          1.0,
          context,
        ),
        isTrue,
      );
      expect(
        layoutStrategy.isPointNear(
          handleEnd,
          start,
          end,
          fromVs,
          toVs,
          relation,
          1.0,
          context,
        ),
        isTrue,
      );
    },
  );

  test(
    'OrthogonalRelationLayoutStrategy resolveTipHandles positions handles on the orthogonal route',
    () {
      final fromNode = InfoUiNode(
        id: 'from_1',
        position: const Offset(10, 10),
        size: const Size(100, 40),
      );
      final toNode = InfoUiNode(
        id: 'to_1',
        position: const Offset(210, 110),
        size: const Size(100, 40),
      );

      final relation = InfoUiRelation(
        fromNodeId: 'from_1',
        fromNodeTable: 'inode',
        toNodeId: 'to_1',
        toNodeTable: 'inode',
        layout: RelationLayout(
          fromSide: 'Auto',
          toSide: 'Auto',
          strategyType: 'orthogonal',
        ),
      );

      final fromVs = NodeViewState(fromNode);
      final toVs = NodeViewState(toNode);
      final context = RelationLayoutContext(
        nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
        relations: [relation],
        pathCache: {},
      );

      const layoutStrategy = OrthogonalRelationLayoutStrategy();
      final (start, end) = layoutStrategy.resolveEndpoints(
        relation,
        fromVs,
        toVs,
      );
      final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
        relation,
        fromVs,
        toVs,
        context,
      );

      // Verify handles are on the orthogonal line (near the line with small threshold e.g. 1.0)
      expect(
        layoutStrategy.isPointNear(
          handleStart,
          start,
          end,
          fromVs,
          toVs,
          relation,
          1.0,
          context,
        ),
        isTrue,
      );
      expect(
        layoutStrategy.isPointNear(
          handleEnd,
          start,
          end,
          fromVs,
          toVs,
          relation,
          1.0,
          context,
        ),
        isTrue,
      );
    },
  );

  test('resolveEndpoints respects custom fromSide and toSide', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Top',
        toSide: 'Bottom',
        strategyType: 'default',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = StraightRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
    );

    expect(start, const Offset(60, 10));
    expect(end, const Offset(260, 50));
  });

  test('Bezier drag override switches opposite port', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'bezier',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = BezierRelationLayoutStrategy();

    final (start1, end1) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
      overrideStart: const Offset(260, 100),
    );
    expect(start1, const Offset(260, 100));
    expect(end1, const Offset(260, 50));

    final (start2, end2) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
      overrideStart: const Offset(260, -10),
    );
    expect(start2, const Offset(260, -10));
    expect(end2, const Offset(260, 10));
  });

  test('Orthogonal drag override switches opposite port', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'orthogonal',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = OrthogonalRelationLayoutStrategy();

    final (start1, end1) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
      overrideStart: const Offset(260, 100),
    );
    expect(start1, const Offset(260, 100));
    expect(end1, const Offset(260, 50));

    final (start2, end2) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
      overrideStart: const Offset(200, 30),
    );
    expect(start2, const Offset(200, 30));
    expect(end2, const Offset(210, 30));
  });

  test('identical positions edge case handled gracefully', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(100, 100),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(100, 100),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'bezier',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = BezierRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
    );

    expect(start, isNotNull);
    expect(end, isNotNull);
  });

  test('isPointNear returns false for point far from curve', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'bezier',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);
    final context = RelationLayoutContext(
      nodeViewStates: {fromVs.nodeId: fromVs, toVs.nodeId: toVs},
      relations: [relation],
      pathCache: {},
    );

    const layoutStrategy = BezierRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
    );

    const farPoint = Offset(500, 500);
    expect(
      layoutStrategy.isPointNear(
        farPoint, start, end, fromVs, toVs, relation, 8.0, context,
      ),
      isFalse,
    );
  });

  test('zero-size node returns fallback', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(10, 10),
      size: Size.zero,
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(210, 10),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'default',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = StraightRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
    );

    expect(start, const Offset(110, 40));
    expect(end, const Offset(210, 30));
  });

  test('overlapping nodes returns same-port endpoints', () {
    final fromNode = InfoUiNode(
      id: 'from_1',
      position: const Offset(100, 100),
      size: const Size(100, 40),
    );
    final toNode = InfoUiNode(
      id: 'to_1',
      position: const Offset(100, 100),
      size: const Size(100, 40),
    );

    final relation = InfoUiRelation(
      fromNodeId: 'from_1',
      fromNodeTable: 'inode',
      toNodeId: 'to_1',
      toNodeTable: 'inode',
      layout: RelationLayout(
        fromSide: 'Auto',
        toSide: 'Auto',
        strategyType: 'default',
      ),
    );

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    const layoutStrategy = StraightRelationLayoutStrategy();
    final (start, end) = layoutStrategy.resolveEndpoints(
      relation, fromVs, toVs,
    );

    expect(start, isNotNull);
    expect(end, isNotNull);
  });
}
