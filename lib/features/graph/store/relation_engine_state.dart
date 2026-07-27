import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mycelium/shared/logging.dart';
import 'graph_api.dart';
import 'package:mycelium/src/rust/relation_engine/computed.dart';
import 'package:mycelium/src/rust/relation_engine/config.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/models/commands/patch_helpers.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'invalidation_tracker.dart';

class RelationEngineState {
  final Logger _log = Logger('RelationEngineState');

  final GraphApi _api;
  final InvalidationTracker _tracker = InvalidationTracker();
  RelationEngineConfig _config = const RelationEngineConfig(
    routing: RoutingConfig(
      routingMode: RoutingMode.polyline(),
      obstacleMargin: 45.0,
      cornerRadius: 8.0,
      projectionFactor: 2,
      clampMin: 30.0,
      clampMax: 150.0,
      extensionMin: 8.0,
      extensionScale: 0.1,
    ),
    nudging: NudgingConfig(enabled: true, distance: 4.0, decayFactor: 0.9),
    bundling: BundlingConfig(mode: BundlingMode.none, threshold: 50.0),
    crossingMinimization: true,
    incrementalMode: true,
    body: BodyConfig(
      defaultType: BodyType.uniform,
      taperStartWidth: 2.0,
      taperEndWidth: 2.0,
      widthModulateAmplitude: 1.5,
      widthModulateFrequency: 3.0,
    ),
    endpoint: EndpointConfig(
      defaultStartShape: EndpointShape.none,
      defaultEndShape: EndpointShape.arrow,
      arrowSize: 10.0,
    ),
  );
  Timer? _throttleTimer;
  Timer? _cacheNotifierDebounce;
  bool _recomputeInFlight = false;
  bool _pendingRecompute = false;
  final ValueNotifier<int> cacheNotifier = ValueNotifier<int>(0);

  Map<RawUuid, ComputedRelation> get cache => _tracker.cache;
  InvalidationTracker get tracker => _tracker;

  RelationEngineState({required GraphApi api}) : _api = api;

  void updateConfig(RelationEngineConfig config) {
    _config = config;
    _tracker.onConfigUpdated();
  }

  RelationEngineConfig get config => _config;

  void onNodeMoved(RawUuid nodeId) {
    _tracker.onNodeMoved(nodeId);
    _scheduleRecompute();
  }

  void onRelationAdded(UiRelation relation) {
    _tracker.onRelationAdded(relation);
    _computeSingleRelation(relation);
  }

  Future<void> _computeSingleRelation(UiRelation relation) async {
    try {
      final computed = await _api.computeSingleRelation(
        config: _config,
        edgeId: parseTypedRecordId('IRelation', relation.id),
        fromNodeId: parseTypedRecordId(relation.fromNodeTable, relation.fromNodeId),
        toNodeId: parseTypedRecordId(relation.toNodeTable, relation.toNodeId),
        fromSide: relation.layout?.fromSide,
        toSide: relation.layout?.toSide,
      );
      _tracker.updateCache([computed]);
      _bumpCacheNotifier();
    } catch (e) {
      _log.warning('computeSingleRelation failed for ${relation.id}: $e');
    }
  }

  void _bumpCacheNotifier() {
    _cacheNotifierDebounce?.cancel();
    _cacheNotifierDebounce = Timer(const Duration(milliseconds: 8), () {
      cacheNotifier.value++;
    });
  }

  void onRelationDeleted(RawUuid relationId) {
    _tracker.onRelationDeleted(relationId);
  }

  void onRelationLayoutUpdated(RawUuid relationId) {
    _tracker.onRelationLayoutUpdated(relationId);
    _scheduleRecompute();
  }

  void onRelationStyleUpdated(RawUuid relationId) {
    _tracker.onRelationLayoutUpdated(relationId);
    _scheduleRecompute();
  }

  void _scheduleRecompute() {
    if (_recomputeInFlight) {
      _pendingRecompute = true;
      return;
    }
    _recomputeInFlight = true;
    _throttleTimer?.cancel();
    recomputeDirty().whenComplete(() {
      _recomputeInFlight = false;
      if (_pendingRecompute) {
        _pendingRecompute = false;
        _throttleTimer = Timer(const Duration(milliseconds: 8), () {
          _scheduleRecompute();
        });
      }
    });
  }

  Future<void> recomputeDirty() async {
    if (!_tracker.hasDirtyRelations) return;

    final dirtyIds = _tracker.dirtyRelationIds.toList();

    try {
      final computed = await recompute(dirtyIds: dirtyIds);
      _tracker.updateCache(computed);
      _bumpCacheNotifier();
    } catch (e) {
      _log.warning('Failed to recompute relations: $e');
    }
  }

  Future<List<ComputedRelation>> recompute({List<RawUuid>? dirtyIds}) async {
    try {
      final typedIds = dirtyIds
          ?.map((id) => parseTypedRecordId('IRelation', id))
          .toList();
      final result = await _api.computeRelations(
        config: _config,
        relationIds: typedIds,
      );
      return result;
    } catch (e) {
      _log.warning('Failed to call compute_relations: $e');
      return [];
    }
  }

  void onInitialLoad({required Iterable<UiRelation> relations}) {
    _tracker.clear();
    _tracker.markIdsDirty(relations.map((r) => r.id));
  }

  void dispose() {
    _throttleTimer?.cancel();
    _cacheNotifierDebounce?.cancel();
    _tracker.clear();
    cacheNotifier.dispose();
  }
}
