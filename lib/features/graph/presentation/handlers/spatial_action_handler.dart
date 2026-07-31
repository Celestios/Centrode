import 'dart:ui';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

/// Handles spatial actions: node dragging, canvas panning, positional updates.
///
/// During drag, intermediate positional updates bypass the FFI boundary
/// for performance, modifying local presentation state directly.
/// On gesture release, the accumulated transform is flushed to
/// CommandQueueProcessor as a batch.
abstract class SpatialActionHandler {
  void handleNodeDragStart(
    RawUuid nodeId,
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  );

  void handleNodeDragUpdate(
    RawUuid nodeId,
    Offset delta,
    GeometryAndViewportCapability ctx,
  );

  void handleNodeDragEnd(RawUuid nodeId, GeometryAndViewportCapability ctx);

  void handleCanvasPan(Offset delta, GeometryAndViewportCapability ctx);
}

/// Default spatial action handler with grid snapping and batched persistence.
class DefaultSpatialActionHandler implements SpatialActionHandler {
  const DefaultSpatialActionHandler();

  @override
  void handleNodeDragStart(
    RawUuid nodeId,
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  ) {
    ctx.setNodeDragging(nodeId, true);
  }

  @override
  void handleNodeDragUpdate(
    RawUuid nodeId,
    Offset delta,
    GeometryAndViewportCapability ctx,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null) return;
    ctx.onNodesDrag([(nodeId, vs.positionNotifier.value + delta)]);
  }

  @override
  void handleNodeDragEnd(RawUuid nodeId, GeometryAndViewportCapability ctx) {
    final vs = ctx.nodeViewStates[nodeId];
    ctx.setNodeDragging(nodeId, false);
    if (vs != null) {
      ctx.onNodeMove(nodeId, vs.positionNotifier.value);
    }
  }

  @override
  void handleCanvasPan(Offset delta, GeometryAndViewportCapability ctx) {
    ctx.onNodesDrag([]);
  }
}
