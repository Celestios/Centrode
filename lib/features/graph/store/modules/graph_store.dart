import '../../models/models.dart';

/// Encapsulates canonical O(1) in-memory storage for the graph.
class GraphStore {
  final Map<String, UiNode> _nodesMap = {};
  final Map<String, UiRelation> _relationsMap = {};

  /// O(1) lookup map for nodes by ID.
  Map<String, UiNode> get nodeLookup => _nodesMap;

  /// O(1) lookup map for relations by ID.
  Map<String, UiRelation> get relationLookup => _relationsMap;

  /// Iterable of all nodes.
  Iterable<UiNode> get nodes => _nodesMap.values;

  /// Iterable of all relations.
  Iterable<UiRelation> get relations => _relationsMap.values;

  /// Clears all stored nodes and relations.
  void clearStore() {
    _nodesMap.clear();
    _relationsMap.clear();
  }
}
