import 'dart:math';
import 'dart:ui';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';
import 'package:mycelium/features/graph/models/relation_view_state.dart';
import '../models/models.dart';

class InvalidationTracker {
  final Map<String, ComputedRelation> _cache = {};
  final Map<String, Set<String>> _nodeToRelations = {};
  final Set<String> _dirtyRelationIds = {};

  Map<String, ComputedRelation> get cache => _cache;

  void clear() {
    _cache.clear();
    _nodeToRelations.clear();
    _dirtyRelationIds.clear();
  }

  void indexRelations(
    Iterable<dynamic> relations,
    Map<String, RelationViewStateRecord> nodeViewStates,
  ) {
    _nodeToRelations.clear();
    for (final rel in relations) {
      final fromId = rel.fromNodeId;
      final toId = rel.toNodeId;
      _nodeToRelations.putIfAbsent(fromId, () => {}).add(rel.id);
      _nodeToRelations.putIfAbsent(toId, () => {}).add(rel.id);
    }
  }

  void onNodeMoved(String nodeId) {
    final related = _nodeToRelations[nodeId];
    if (related != null) {
      _dirtyRelationIds.addAll(related);
    }
  }

  void onRelationAdded(UiRelation relation) {
    final fromId = relation.fromNodeId;
    final toId = relation.toNodeId;
    _nodeToRelations.putIfAbsent(fromId, () => {}).add(relation.id);
    _nodeToRelations.putIfAbsent(toId, () => {}).add(relation.id);
    _dirtyRelationIds.add(relation.id);
  }

  void onRelationDeleted(String relationId) {
    _cache.remove(relationId);
    _dirtyRelationIds.remove(relationId);
    for (final entry in _nodeToRelations.values) {
      entry.remove(relationId);
    }
  }

  void onRelationLayoutUpdated(String relationId) {
    _dirtyRelationIds.add(relationId);
  }

  void onConfigUpdated() {
    _dirtyRelationIds.addAll(_cache.keys);
  }

  Set<String> get dirtyRelationIds => Set.from(_dirtyRelationIds);

  bool get hasDirtyRelations => _dirtyRelationIds.isNotEmpty;

  void markAllDirty() {
    for (final entry in _nodeToRelations.values) {
      _dirtyRelationIds.addAll(entry);
    }
  }

  void clearDirty() {
    _dirtyRelationIds.clear();
  }

  void updateCache(List<ComputedRelation> computed) {
    for (final rel in computed) {
      _cache[rel.id] = rel;
      _dirtyRelationIds.remove(rel.id);
    }
  }

  ComputedRelation? getCached(String relationId) {
    return _cache[relationId];
  }

  List<ComputedRelation> getCachedAll() {
    return _cache.values.toList();
  }

  bool shouldRecompute(String relationId) {
    return _dirtyRelationIds.contains(relationId);
  }

  List<String> getRelationIdsForNode(String nodeId) {
    return _nodeToRelations[nodeId]?.toList() ?? [];
  }

  Rect computeBbox(List<ComputedRelation> relations) {
    if (relations.isEmpty) {
      return Rect.zero;
    }
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final rel in relations) {
      for (final p in rel.pathPoints) {
        minX = min(minX, p.x);
        minY = min(minY, p.y);
        maxX = max(maxX, p.x);
        maxY = max(maxY, p.y);
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
