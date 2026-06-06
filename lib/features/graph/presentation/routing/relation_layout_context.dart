import 'package:flutter/painting.dart';
import '../view_state.dart';
import '../../models/graph_relation.dart';

/// Context containing the spatial information of the graph.
/// Passed down to layout strategies to enable obstacle avoidance.
class RelationLayoutContext {
  final Map<String, NodeViewState> nodeViewStates;
  final List<UiRelation> relations;
  final Map<String, List<Offset>> pathCache;

  RelationLayoutContext({
    required this.nodeViewStates,
    required this.relations,
    required this.pathCache,
  });

  /// Retrieves bounding boxes of all nodes except the source and target nodes.
  List<Rect> getObstacles({
    required String excludeFromId,
    required String excludeToId,
  }) {
    final obstacles = <Rect>[];
    for (final entry in nodeViewStates.entries) {
      if (entry.key == excludeFromId || entry.key == excludeToId) continue;
      obstacles.add(entry.value.rect);
    }
    return obstacles;
  }
}
