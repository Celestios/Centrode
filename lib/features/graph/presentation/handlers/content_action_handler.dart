import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'package:mycelium/features/graph/engine/interaction_context.dart';

/// Handles content actions: node taps, double-taps, text edits, state toggles.
///
/// Manages selection, edit mode entry, and node-specific content mutations
/// (e.g., TaskUiNode completion toggles, text edits).
abstract class ContentActionHandler {
  void handleNodeTap(
    RawUuid nodeId,
    SelectionCapability ctx,
  );

  void handleNodeDoubleTap(
    RawUuid nodeId,
    GeometryAndViewportCapability ctx,
  );
}

/// Default content action handler for selection and edit mode.
class DefaultContentActionHandler implements ContentActionHandler {
  const DefaultContentActionHandler();

  @override
  void handleNodeTap(
    RawUuid nodeId,
    SelectionCapability ctx,
  ) {
    ctx.onSelectEntity(nodeId);
  }

  @override
  void handleNodeDoubleTap(
    RawUuid nodeId,
    GeometryAndViewportCapability ctx,
  ) {
    ctx.onEnterEditMode(nodeId);
  }
}
