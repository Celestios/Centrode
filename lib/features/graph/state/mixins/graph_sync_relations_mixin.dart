import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../../src/rust/domain/relations.dart';

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
  Future<void> createRelation(String fromId, String toId) async {
    final fromNode = nodeLookup[fromId];
    final toNode = nodeLookup[toId];
    if (fromNode == null || toNode == null) return;

    // A. Pre-flight Validation (O(1) duplicate check)
    final bool relationExists = relationLookup.values.any(
      (r) => r.fromNodeId == fromId && r.toNodeId == toId,
    );

    if (relationExists) {
      _relLog.fine(
        'Pre-flight Validation: Relation $fromId -> $toId already exists. Aborting quietly.',
      );
      return;
    }

    // B. Create Relation Input - Must inject table prefixes to satisfy Rust's DB parser
    final input = RelationInput(
      from: "${getTableName(fromNode)}:$fromId",
      to: "${getTableName(toNode)}:$toId",
      props: IRelation(
        id: null,
        inId: null,
        outId: null,
        verb: "related",
        aesthetics: null,
        directionless: false,
        layer: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    try {
      // C. Pessimistic FFI Call
      await api.createRelation(input: input);

      // D. Hydrate the UI with the confirmed mathematical state
      await loadGraph();
    } catch (e) {
      _relLog.severe('Failed to create relation', e);
      onError("Relation creation failed: $e");
    }
  }
}
