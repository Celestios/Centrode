import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart' as rust;
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'invalidation_tracker.dart';

class RelationEngineState {
  final Logger _log = Logger('RelationEngineState');

  final rust.AppHandle _api;
  final InvalidationTracker _tracker = InvalidationTracker();
  RelationEngineConfig _config = const RelationEngineConfig(
    routing: RoutingConfig(
      routingMode: RoutingMode.polyline,
      obstacleMargin: 45.0,
      cornerRadius: 8.0,
      bezierCurvature: 20,
      bezierProjectionFactor: 2,
      bezierClampMin: 30.0,
      bezierClampMax: 150.0,
    ),
    nudging: NudgingConfig(enabled: true, distance: 4.0),
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
      defaultStartShape: EndpointShapeType.none,
      defaultEndShape: EndpointShapeType.arrow,
      arrowSize: 10.0,
    ),
    snake: SnakeConfig(
      amplitude: 20.0,
      frequency: 3.0,
      obstacleAvoidance: false,
    ),
  );
  Timer? _throttleTimer;
  bool _recomputeInFlight = false;
  bool _pendingRecompute = false;
  final ValueNotifier<int> cacheNotifier = ValueNotifier<int>(0);

  Map<String, ComputedRelation> get cache => _tracker.cache;
  InvalidationTracker get tracker => _tracker;

  RelationEngineState({required rust.AppHandle api}) : _api = api;

  void updateConfig(RelationEngineConfig config) {
    _config = config;
    _tracker.onConfigUpdated();
  }

  RelationEngineConfig get config => _config;

  void onNodeMoved(String nodeId) {
    _tracker.onNodeMoved(nodeId);
    _scheduleRecompute();
  }

  void onRelationAdded(String relationId) {
    _tracker.onRelationAdded(relationId);
    _scheduleRecompute();
  }

  void onRelationDeleted(String relationId) {
    _tracker.onRelationDeleted(relationId);
  }

  void onRelationLayoutUpdated(String relationId) {
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
    _log.fine('Recomputing ${dirtyIds.length} dirty relations');

    try {
      final computed = await recompute(dirtyIds: dirtyIds);
      _tracker.updateCache(computed);
      cacheNotifier.value++;
    } catch (e) {
      _log.warning('Failed to recompute relations: $e');
    }
  }

  Future<List<ComputedRelation>> recompute({List<String>? dirtyIds}) async {
    try {
      final result = await _api.computeRelations(
        config: _config,
        relationIds: dirtyIds,
      );
      return result;
    } catch (e) {
      _log.warning('Failed to call compute_relations: $e');
      return [];
    }
  }

  Future<ComputedRelation?> computeSingleRelation({
    required String edgeId,
    required String fromNodeId,
    required String toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    double? overrideStartX,
    double? overrideStartY,
    double? overrideEndX,
    double? overrideEndY,
  }) async {
    try {
      return await _api.computeSingleRelation(
        config: _config,
        edgeId: edgeId,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        fromSide: fromSide,
        toSide: toSide,
        overrideStartX: overrideStartX,
        overrideStartY: overrideStartY,
        overrideEndX: overrideEndX,
        overrideEndY: overrideEndY,
      );
    } catch (e) {
      _log.warning('Failed to compute single relation: $e');
      return null;
    }
  }

  void onInitialLoad({
    required Iterable<UiRelation> relations,
    required Map<String, NodeViewState> nodeViewStates,
  }) {
    _tracker.clear();
    _tracker.indexRelations(relations, nodeViewStates);
    _tracker.markAllDirty();
  }

  void dispose() {
    _throttleTimer?.cancel();
    _tracker.clear();
    cacheNotifier.dispose();
  }
}
