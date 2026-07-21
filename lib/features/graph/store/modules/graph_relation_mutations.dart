import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../../models/commands.dart';
import '../../models/graph_relation.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';

/// Relation mutation operations for the graph.
class GraphRelationMutations {
  final Logger _relLog = Logger('GraphRelationMutations');
  final CommandQueueProcessor controller;

  GraphRelationMutations(this.controller);

  /// Creates a relation between two nodes.
  /// Called by InteractionController when relation drawing completes.
  /// Implements pre-flight validation to prevent duplicate relation crashes.
  void createRelation(
    String fromId,
    String toId, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
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
      verb: verb ?? 'default',
      layout: RelationLayout(
        fromSide: fromSide,
        toSide: toSide,
        strategyType: 'bezier',
      ),
    );

    // OPTIMISTIC INSERTION (T=0.0ms)
    controller.store.relationLookup[relation.id] = relation;
    controller.styleUpdater?.updateStyleForRelation(relation.id);

    final cmd = CreateRelationCommand(
      targetId: relation.id,
      api: controller.syncEngine.api,
      relation: relation,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: relation.id,
        tableName: 'IRelation',
        type: GraphUpdateType.relationAdded,
        payload: relation,
      ),
    );
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
      relation: relation,
      controller: controller,
    );

    // OPTIMISTIC TEARDOWN
    controller.store.relationLookup.remove(id);

    // Queue command with immediate execution
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: 'IRelation',
        type: GraphUpdateType.relationDeleted,
      ),
    );
    controller.triggerUpdate();
  }

  /// Updates the layout and endpoints of a relation.
  void updateRelationLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) {
    final relation = controller.store.relationLookup[id];
    if (relation == null) return;

    final oldRelation = UiRelation.copy(relation);
    if (oldRelation == null) return;

    final fromNode = fromNodeId != null
        ? controller.store.nodeLookup[fromNodeId]
        : null;
    final toNode = toNodeId != null
        ? controller.store.nodeLookup[toNodeId]
        : null;

    final newLayout = RelationLayout(
      fromSide: fromSide ?? relation.layout?.fromSide,
      toSide: toSide ?? relation.layout?.toSide,
      strategyType: strategyType ?? relation.layout?.strategyType ?? 'default',
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
      tableName: 'IRelation',
      api: controller.syncEngine.api,
      oldLayout: oldRelation.layout,
      newLayout: updatedRelation.layout,
      oldStyle: oldRelation.style,
      newStyle: updatedRelation.style,
      oldRelation: oldRelation,
      controller: controller,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: 'IRelation',
        type: GraphUpdateType.relationLayout,
        payload: updatedRelation.layout,
      ),
    );

    controller.triggerUpdate();
  }

  void updateRelationsLayout(
    List<String> ids, {
    String? strategyType,
  }) {
    if (ids.isEmpty) return;

    final Map<String, RelationLayout?> oldLayouts = {};
    final Map<String, RelationLayout?> newLayouts = {};
    final Map<String, RelationStyle?> oldStyles = {};
    final Map<String, RelationStyle?> newStyles = {};
    final Map<String, UiRelation> oldRelations = {};

    for (final id in ids) {
      final relation = controller.store.relationLookup[id];
      if (relation == null) continue;

      final oldRelation = UiRelation.copy(relation);
      if (oldRelation == null) continue;

      final newLayout = RelationLayout(
        fromSide: relation.layout?.fromSide,
        toSide: relation.layout?.toSide,
        strategyType: strategyType ?? relation.layout?.strategyType ?? 'default',
      );

      final updatedRelation = (relation as InfoUiRelation).copyWith(
        layout: newLayout,
      );

      // OPTIMISTIC UPDATE
      controller.store.relationLookup[id] = updatedRelation;

      oldLayouts[id] = oldRelation.layout;
      newLayouts[id] = updatedRelation.layout;
      oldStyles[id] = oldRelation.style;
      newStyles[id] = updatedRelation.style;
      oldRelations[id] = oldRelation;
    }

    if (newLayouts.isEmpty) return;

    final cmd = UpdateRelationsLayoutCommand(
      targetId: newLayouts.keys.first,
      api: controller.syncEngine.api,
      oldLayouts: oldLayouts,
      newLayouts: newLayouts,
      oldStyles: oldStyles,
      newStyles: newStyles,
      oldRelations: oldRelations,
      controller: controller,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    for (final id in newLayouts.keys) {
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.relationLayout,
          payload: newLayouts[id],
        ),
      );
    }

    controller.triggerUpdate();
  }
}
