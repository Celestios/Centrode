import 'package:flutter/foundation.dart';
import '../../domain/models.dart';

/// Tier 1: Canonical $O(1)$ in-memory storage.
mixin GraphStoreMixin on ChangeNotifier {
  // Internal storage maps (protected for mixin hierarchy)
  final Map<String, UiNode> _nodesMap = {};
  final Map<String, UiRelation> _relationsMap = {};

  /// O(1) lookup map for nodes by ID.
  ///
  /// This is the primary access pattern for existence checks and lookups.
  Map<String, UiNode> get nodeLookup => _nodesMap;

  /// O(1) lookup map for relations by ID.
  Map<String, UiRelation> get relationLookup => _relationsMap;

  /// Iterable of all nodes for iteration purposes.
  ///
  /// Use [nodeLookup] for O(1) access by ID.
  Iterable<UiNode> get nodes => _nodesMap.values;

  /// Iterable of all relations for iteration purposes.
  ///
  /// Use [relationLookup] for O(1) access by ID.
  Iterable<UiRelation> get relations => _relationsMap.values;

  /// Returns the database table name for a given node type.
  String getTableName(UiNode node) {
    switch (node.type) {
      case UiNodeType.info:
        return "info_node";
      case UiNodeType.task:
        return "task_node";
      case UiNodeType.inter:
        return "inter_node";
    }
  }

  /// Clears all stored nodes and relations.
  void clearStore() {
    _nodesMap.clear();
    _relationsMap.clear();
  }
}
