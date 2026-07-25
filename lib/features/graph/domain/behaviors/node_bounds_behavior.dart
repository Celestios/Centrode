import 'dart:ui';
import 'package:mycelium/features/graph/models/graph_node.dart';

/// Computes variant-specific bounding boxes.
///
/// Each behavior is keyed to a specific [UiNodes] enum value.
/// The default implementation uses a standard axis-aligned rectangle;
/// variant-specific subclasses override for shapes, frames, etc.
abstract class NodeBoundsBehavior {
  Rect computeBounds(UiNode node, Size size, Offset position);
}

/// Default bounds: axis-aligned rectangle from position and size.
class DefaultNodeBounds implements NodeBoundsBehavior {
  const DefaultNodeBounds();

  @override
  Rect computeBounds(UiNode node, Size size, Offset position) {
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
}

/// Shape nodes compute bounds centered on the position.
class ShapeNodeBounds implements NodeBoundsBehavior {
  const ShapeNodeBounds();

  @override
  Rect computeBounds(UiNode node, Size size, Offset position) {
    return Rect.fromCenter(
      center: position,
      width: size.width,
      height: size.height,
    );
  }
}

/// Drawing nodes use path-proximity hit testing (no standard rect bounds).
/// This returns a generous bounding rect; actual hit testing is handled
/// by [HitTestResolver._isPointNearDrawing].
class DrawingNodeBounds implements NodeBoundsBehavior {
  const DrawingNodeBounds();

  @override
  Rect computeBounds(UiNode node, Size size, Offset position) {
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
}
