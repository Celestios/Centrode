import 'dart:math';
import 'dart:ui';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';
import '../models/models.dart';

class InvalidationTracker {
  final Map<String, ComputedRelation> _cache = {};
  final Set<String> _dirtyRelationIds = {};

  Map<String, ComputedRelation> get cache => _cache;

  void clear() {
    _cache.clear();
    _dirtyRelationIds.clear();
  }

  void onNodeMoved(String nodeId) {
    _dirtyRelationIds.addAll(_cache.keys);
  }

  void onRelationAdded(UiRelation relation) {
    _dirtyRelationIds.add(relation.id);
  }

  void onRelationDeleted(String relationId) {
    _cache.remove(relationId);
    _dirtyRelationIds.remove(relationId);
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
    _dirtyRelationIds.addAll(_cache.keys);
  }

  void markIdsDirty(Iterable<String> ids) {
    _dirtyRelationIds.addAll(ids);
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
    return _cache.keys.where((id) {
      final rel = _cache[id];
      return rel != null && rel.dependsOnNodes.contains(nodeId);
    }).toList();
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
