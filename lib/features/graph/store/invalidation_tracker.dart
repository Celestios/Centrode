import 'dart:math';
import 'dart:ui';
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import '../models/models.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class InvalidationTracker {
  final Map<RawUuid, ComputedRelation> _cache = {};
  final Set<RawUuid> _dirtyRelationIds = {};

  Map<RawUuid, ComputedRelation> get cache => _cache;

  void clear() {
    _cache.clear();
    _dirtyRelationIds.clear();
  }

  void onNodeMoved(RawUuid nodeId) {
    _dirtyRelationIds.addAll(_cache.keys);
  }

  void onRelationAdded(UiRelation relation) {
    _dirtyRelationIds.add(relation.id);
  }

  void onRelationDeleted(RawUuid relationId) {
    _cache.remove(relationId);
    _dirtyRelationIds.remove(relationId);
  }

  void onRelationLayoutUpdated(RawUuid relationId) {
    _dirtyRelationIds.add(relationId);
  }

  void onConfigUpdated() {
    _dirtyRelationIds.addAll(_cache.keys);
  }

  Set<RawUuid> get dirtyRelationIds => Set.from(_dirtyRelationIds);

  bool get hasDirtyRelations => _dirtyRelationIds.isNotEmpty;

  void markAllDirty() {
    _dirtyRelationIds.addAll(_cache.keys);
  }

  void markIdsDirty(Iterable<RawUuid> ids) {
    _dirtyRelationIds.addAll(ids);
  }

  void clearDirty() {
    _dirtyRelationIds.clear();
  }

  void updateCache(List<ComputedRelation> computed) {
    for (final rel in computed) {
      final key = RawUuid.fromString(rel.id.key.uuid);
      _cache[key] = rel;
      _dirtyRelationIds.remove(key);
    }
  }

  ComputedRelation? getCached(RawUuid relationId) {
    return _cache[relationId];
  }

  List<ComputedRelation> getCachedAll() {
    return _cache.values.toList();
  }

  bool shouldRecompute(RawUuid relationId) {
    return _dirtyRelationIds.contains(relationId);
  }

  List<String> getRelationIdsForNode(RawUuid nodeId) {
    final nodeStr = nodeId.toUuidString();
    return _cache.keys
        .where((key) {
          final rel = _cache[key];
          return rel != null && rel.dependsOnNodes.any((r) => r.key.uuid == nodeStr);
        })
        .map((key) => key.toUuidString())
        .toList();
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
