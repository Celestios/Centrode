import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
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
  void createRelation(String fromId, String toId, {String? fromSide, String? toSide}) {
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
      layout: RelationLayout(
        fromSide: fromSide ?? 'Auto',
        toSide: toSide ?? 'Auto',
      ),
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

  /// Deletes a relation with immediate command execution via CommandProcessor.
  Future<void> deleteRelation(String id) async {
    final relation = controller.store.relationLookup[id];
    if (relation == null) return;

    _relLog.info('Initiating optimistic UI teardown for relation: $id');

    // Prepare Command for FFI with rollback
    final cmd = DeleteRelationCommand(
      targetId: id,
      api: controller.syncEngine.api,
      tableName: 'IRelation',
      onUndo: () {
        _relLog.warning('Deletion rejected. Re-hydrating relation: $id');
        controller.store.relationLookup[id] = relation;
        controller.triggerUpdate(); // Force canvas rebuild to re-mount the rehydrated relation
      },
    );

    // OPTIMISTIC TEARDOWN
    controller.store.relationLookup.remove(id);

    // Queue command with immediate execution
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.triggerUpdate();
  }

  /// Updates the layout and endpoints of a relation.
  void updateRelationLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    String? fromSide,
    String? toSide,
  }) {
    final relation = controller.store.relationLookup[id];
    if (relation == null) return;

    final oldRelation = UiRelation.copy(relation);
    if (oldRelation == null) return;

    final fromNode = fromNodeId != null ? controller.store.nodeLookup[fromNodeId] : null;
    final toNode = toNodeId != null ? controller.store.nodeLookup[toNodeId] : null;

    final newLayout = RelationLayout(
      fromSide: fromSide ?? relation.layout?.fromSide ?? 'Auto',
      toSide: toSide ?? relation.layout?.toSide ?? 'Auto',
    );

    final updatedRelation = (relation as InfoUiRelation).copyWith(
      fromNodeId: fromNodeId ?? relation.fromNodeId,
      fromNodeTable: fromNode?.tableName ?? relation.fromNodeTable,
      toNodeId: toNodeId ?? relation.toNodeId,
      toNodeTable: toNode?.tableName ?? relation.toNodeTable,
      layout: newLayout,
    );

    // OPTIMISTIC UPDATE
    controller.store.relationLookup[id] = updatedRelation;

    final cmd = UpdateRelationLayoutCommand(
      targetId: id,
      api: controller.syncEngine.api,
      newRelation: updatedRelation,
      onUndo: () {
        _relLog.warning('Relation layout update failed or rejected. Rolling back.');
        controller.store.relationLookup[id] = oldRelation;
        controller.triggerUpdate();
      },
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.triggerUpdate();
  }
}


