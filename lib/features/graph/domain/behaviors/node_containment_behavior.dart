import 'dart:ui';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/graph_node.dart';

/// Determines child node containment for composite nodes (frames and containers).
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

/// Container nodes contain children whose center falls within their local bounding box.
class ContainerContainment implements NodeContainmentBehavior {
  const ContainerContainment();

  @override
  bool containsChild(UiNode parent, Offset childPosition, Size childSize) {
    final parentRect = Rect.fromLTWH(
      0.0,
      0.0,
      parent.size.width,
      parent.size.height,
    );
    final childCenter =
        childPosition + Offset(childSize.width / 2, childSize.height / 2);
    return parentRect.contains(childCenter);
  }
}

/// Cycle protection check to ensure candidateAncestor is not an ancestor/parent of candidateDescendant.
bool isAncestorOf(UiNode candidateAncestor, UiNode candidateDescendant, Map<RawUuid, UiNode> nodeLookup) {
  RawUuid? currentParentId = candidateDescendant.parentContainerId;
  int depth = 0;
  final visited = <RawUuid>{};

  while (currentParentId != null && depth < 32) {
    if (!visited.add(currentParentId)) return true; // Cycle detected
    if (currentParentId == candidateAncestor.id) return true;

    final parent = nodeLookup[currentParentId];
    if (parent == null) break;
    currentParentId = parent.parentContainerId;
    depth++;
  }
  return false;
}
