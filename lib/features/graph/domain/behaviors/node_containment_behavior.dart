import 'dart:ui';
import 'package:centrode/features/graph/models/graph_node.dart';

/// Determines child node containment for composite nodes (frames).
abstract class NodeContainmentBehavior {
  bool containsChild(UiNode parent, Offset childPosition, Size childSize);
}

/// Default: no containment logic (most nodes don't contain children).
class DefaultContainment implements NodeContainmentBehavior {
  const DefaultContainment();

  @override
  bool containsChild(UiNode parent, Offset childPosition, Size childSize) {
    return false;
  }
}

/// Frame nodes contain children that fall within their bounds.
class FrameContainment implements NodeContainmentBehavior {
  const FrameContainment();

  @override
  bool containsChild(UiNode parent, Offset childPosition, Size childSize) {
    final parentRect = Rect.fromLTWH(
      parent.position.dx,
      parent.position.dy,
      parent.size.width,
      parent.size.height,
    );
    final childCenter =
        childPosition + Offset(childSize.width / 2, childSize.height / 2);
    return parentRect.contains(childCenter);
  }
}
