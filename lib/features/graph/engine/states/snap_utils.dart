part of '../base_interaction_state.dart';

class SnapResult {
  final String? snappedNodeId;
  final Port? snappedPort;
  final String? hoveredNodeId;

  const SnapResult({
    this.snappedNodeId,
    this.snappedPort,
    this.hoveredNodeId,
  });
}

SnapResult findNearestSnap(
  Offset pCanvas,
  GeometryCapability ctx,
  Set<String> excludeNodeIds,
) {
  String? snappedId;
  Port? snappedPort;
  String? hoveredNodeId;
  double bestTargetDist = double.infinity;

  final nodeIds = ctx.zOrder.reversed.toList();
  if (nodeIds.isEmpty) {
    nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
  }

  for (final nodeId in nodeIds) {
    if (excludeNodeIds.contains(nodeId)) continue;

    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) continue;
    if (vs.sizeNotifier.value == Size.zero) continue;

    final port = vs.getClosestPortNew(pCanvas);
    if (port == null) continue;

    final dist = (pCanvas - port.edgePosition).distance;
    if (dist < AppConfig.interaction.snapDistance && dist < bestTargetDist) {
      bestTargetDist = dist;
      snappedId = nodeId;
      snappedPort = port;
    }

    if (hoveredNodeId == null && vs.rect.inflate(20.0).contains(pCanvas)) {
      hoveredNodeId = nodeId;
    }
  }

  if (snappedId != null) {
    hoveredNodeId = snappedId;
  }

  return SnapResult(
    snappedNodeId: snappedId,
    snappedPort: snappedPort,
    hoveredNodeId: hoveredNodeId,
  );
}
