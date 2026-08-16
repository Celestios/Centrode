part of '../base_interaction_state.dart';

class SnapResult {
  final RawUuid? snappedNodeId;
  final Port? snappedPort;
  final RawUuid? hoveredNodeId;

  const SnapResult({
    this.snappedNodeId,
    this.snappedPort,
    this.hoveredNodeId,
  });
}

SnapResult findNearestSnap(
  Offset pCanvas,
  GeometryCapability ctx,
  Set<RawUuid> excludeNodeIds,
) {
  RawUuid? snappedId;
  Port? snappedPort;
  RawUuid? hoveredNodeId;
  double bestTargetDist = double.infinity;

  final activeScope = ctx.activeScope;
  final nodeIds = resolveZOrderToNodeIds(ctx.zOrder, ctx.nodeViewStates);

  for (final nodeId in nodeIds) {
    if (excludeNodeIds.contains(nodeId)) continue;

    final node = ctx.getNode(nodeId);
    if (node == null) continue;

    final bool isInsideScope;
    final bool isOutsideScope;
    final ContainerViewportScope? containerScope =
        activeScope is ContainerViewportScope ? activeScope : null;

    if (containerScope != null) {
      isInsideScope = node.parentContainerId == containerScope.containerId;
      final parentScope = containerScope.parentScope;
      isOutsideScope = node.id != containerScope.containerId &&
          node.parentContainerId ==
              (parentScope is ContainerViewportScope
                  ? parentScope.containerId
                  : null);
    } else {
      isInsideScope = node.parentContainerId == null &&
          !(node is ContainerUiNode && !node.isClosed);
      isOutsideScope = false;
    }

    if (!isInsideScope && !isOutsideScope) continue;

    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) continue;
    if (vs.sizeNotifier.value == Size.zero) continue;

    if (isInsideScope) {
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
    } else if (isOutsideScope && containerScope != null) {
      final scope = containerScope;
      final parentContainer = ctx.getNode(scope.containerId) as ContainerUiNode?;
      final containerPos = parentContainer?.position ?? scope.containerPositionInParent;
      final effectiveOuterSize = (scope.outerSize.width > 0 && scope.outerSize.height > 0)
          ? scope.outerSize
          : (parentContainer != null
              ? const DefaultNodeLayoutStrategy().calculateSize(parentContainer).size
              : const Size(300.0, 180.0));
      final aspectRatio = effectiveOuterSize.height / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
      final sx = 1600.0 / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
      final sy = (1600.0 * aspectRatio) / (effectiveOuterSize.height > 0 ? effectiveOuterSize.height : 1.0);

      final pParent = Offset((pCanvas.dx / sx) + containerPos.dx, (pCanvas.dy / sy) + containerPos.dy);
      final port = vs.getClosestPortNew(pParent);
      if (port == null) continue;

      final localPortPos = Offset((port.edgePosition.dx - containerPos.dx) * sx, (port.edgePosition.dy - containerPos.dy) * sy);
      final dist = (pCanvas - localPortPos).distance;
      if (dist < AppConfig.interaction.snapDistance && dist < bestTargetDist) {
        bestTargetDist = dist;
        snappedId = nodeId;
        snappedPort = port;
      }

      final outsideLocalRect = Rect.fromLTWH(
        (node.position.dx - containerPos.dx) * sx,
        (node.position.dy - containerPos.dy) * sy,
        node.size.width * sx,
        node.size.height * sy,
      );
      if (hoveredNodeId == null && outsideLocalRect.inflate(20.0).contains(pCanvas)) {
        hoveredNodeId = nodeId;
      }
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
