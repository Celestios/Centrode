import 'package:centrode/features/graph/models/graph_node.dart';
import 'node_bounds_behavior.dart';
import 'node_containment_behavior.dart';

/// Fixed-size registry of per-variant behaviors, indexed by [UiNodes] enum.
///
/// O(1) lookup with zero map hashing overhead. Behaviors are registered at
/// construction time and remain constant for the lifetime of the registry.
class BehaviorRegistry {
  late final List<NodeBoundsBehavior> _boundsBehaviors;
  late final List<NodeContainmentBehavior> _containmentBehaviors;

  BehaviorRegistry() {
    _boundsBehaviors = List<NodeBoundsBehavior>.generate(
      UiNodes.values.length,
      (_) => const DefaultNodeBounds(),
    );
    _boundsBehaviors[UiNodes.shape.index] = const ShapeNodeBounds();
    _boundsBehaviors[UiNodes.drawing.index] = const DrawingNodeBounds();

    _containmentBehaviors = List<NodeContainmentBehavior>.generate(
      UiNodes.values.length,
      (_) => const DefaultContainment(),
    );
    _containmentBehaviors[UiNodes.frame.index] = const FrameContainment();
  }

  NodeBoundsBehavior getBoundsBehavior(UiNodes type) {
    return _boundsBehaviors[type.index];
  }

  NodeContainmentBehavior getContainmentBehavior(UiNodes type) {
    return _containmentBehaviors[type.index];
  }
}
