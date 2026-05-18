import 'package:logging/logging.dart';
import '../../models/commands.dart';
import '../../models/graph_relation.dart';
import '../graph_data_controller.dart';

/// Relation mutation operations for the graph.
class GraphRelationMutations {
  final Logger _relLog = Logger('GraphRelationMutations');
  final GraphDataController controller;

  GraphRelationMutations(this.controller);

  /// Creates a relation between two nodes.
  /// Called by InteractionController when relation drawing completes.
  /// Implements pre-flight validation to prevent duplicate relation crashes.
  void createRelation(String fromId, String toId) {
    final bool relationExists = controller.store.relationLookup.values.any(
      (r) => r.fromNodeId == fromId && r.toNodeId == toId,
    );

    if (relationExists) {
      _relLog.fine(
        'Pre-flight Validation: Relation $fromId -> $toId already exists. Aborting quietly.',
      );
      return;
    }

    final fromNode = controller.store.nodeLookup[fromId];
    final toNode = controller.store.nodeLookup[toId];
    if (fromNode == null || toNode == null) {
      _relLog.warning(
        'Failed to create relation: source or target node not found in store lookup.',
      );
      return;
    }

    final relation = InfoUiRelation(
      fromNodeId: fromId,
      fromNodeTable: fromNode.tableName,
      toNodeId: toId,
      toNodeTable: toNode.tableName,
    );

    // OPTIMISTIC INSERTION (T=0.0ms)
    controller.store.relationLookup[relation.id] = relation;
    controller.styleManager.updateStyleForRelation(relation.id);

    final cmd = CreateRelationCommand(
      targetId: relation.id,
      api: controller.syncEngine.api,
      relation: relation,
      reloadGraph: controller.loadGraph,
      onUndo: () {
        _relLog.warning('Relation creation rejected or failed. Removing relation: ${relation.id}');
        controller.store.relationLookup.remove(relation.id);
        controller.triggerUpdate();
      },
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.triggerUpdate();
  }
}
