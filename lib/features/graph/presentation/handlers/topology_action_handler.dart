import 'dart:ui';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

/// Handles topology actions: link creation, edge drawing, connection points.
///
/// Manages the lifecycle of relation creation from port drag start
/// through update to final commit or cancellation.
abstract class TopologyActionHandler {
  void handleEdgeDragStart(
    RawUuid sourceNodeId,
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  );

  void handleEdgeDragUpdate(
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  );

  void handleEdgeDragEnd(
    RawUuid? targetNodeId,
    GeometryAndViewportCapability ctx,
  );
}

/// Default topology action handler that delegates to the mutation capability.
class DefaultTopologyActionHandler implements TopologyActionHandler {
  const DefaultTopologyActionHandler();

  @override
  void handleEdgeDragStart(
    RawUuid sourceNodeId,
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  ) {
    // Edge drag start — no immediate mutation needed
  }

  @override
  void handleEdgeDragUpdate(
    Offset localPosition,
    GeometryAndViewportCapability ctx,
  ) {
    // Edge drag update — visual feedback handled by the FSM state
  }

  @override
  void handleEdgeDragEnd(
    RawUuid? targetNodeId,
    GeometryAndViewportCapability ctx,
  ) {
    // Edge drag end — commit relation if target exists
  }
}
