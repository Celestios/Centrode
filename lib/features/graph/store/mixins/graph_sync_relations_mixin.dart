import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import '../../models/commands.dart';

import 'graph_store_mixin.dart';
import 'graph_spatial_mixin.dart';
import 'graph_sync_base_mixin.dart';

/// Relation mutation operations for the graph sync hierarchy.
///
/// This mixin provides relation-related mutation operations including:
/// - **createRelation**: Relation creation with pre-flight validation
///
/// ## Architecture
///
/// This mixin depends on [GraphSyncBaseMixin] for access to:
/// - [api]: FFI handle for Rust communication
/// - [onError]: Error callback for failure handling
/// - [loadGraph]: Graph reloading after relation creation
///
/// ## Key Patterns
///
/// ### Pre-flight Validation
/// Before creating a relation, the mixin checks if an identical relation
/// already exists to prevent duplicate relation crashes in the database.
///
/// ### Pessimistic FFI Call
/// Unlike node creation, relation creation is pessimistic - it waits for
/// the FFI call to complete before updating the UI, then reloads the
/// entire graph to ensure consistency.
///
/// See also:
/// - [GraphSyncBaseMixin] for the foundation infrastructure
/// - [GraphNodeMutationsMixin] for node operations
/// - [GraphPropertyMutationsMixin] for property operations
mixin GraphRelationMutationsMixin
    on ChangeNotifier, GraphStoreMixin, GraphSpatialMixin, GraphSyncBaseMixin {
  final Logger _relLog = Logger('GraphRelationMutationsMixin');

  /// Creates a relation between two nodes.
  /// Called by InteractionController when relation drawing completes.
  /// Implements pre-flight validation to prevent duplicate relation crashes.
  ///
  void createRelation(String fromId, String toId) {
    final bool relationExists = relationLookup.values.any(
      (r) => r.fromNodeId == fromId && r.toNodeId == toId,
    );

    if (relationExists) {
      _relLog.fine(
        'Pre-flight Validation: Relation $fromId -> $toId already exists. Aborting quietly.',
      );
      return;
    }

    final relation = InfoUiRelation(fromNodeId: fromId, toNodeId: toId);

    final cmd = CreateRelationCommand(
      targetId: relation.id,
      api: api,
      relation: relation,
      reloadGraph: loadGraph,
    );
    processor.queueCommand(cmd, immediate: true);
  }
}
