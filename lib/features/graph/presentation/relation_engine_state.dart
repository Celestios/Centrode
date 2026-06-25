import 'dart:async';
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
  RelationEngineConfig _config = RelationEngineConfig(
    routingMode: RoutingMode.polyline,
    obstacleMargin: 45.0,
    cornerRadius: 8.0,
    incrementalMode: true,
    nudgingEnabled: true,
    nudgingDistance: 4.0,
    bundlingMode: BundlingMode.none,
    bundlingThreshold: 50.0,
    crossingMinimization: true,
    bezierCurvature: 0.25,
    bezierProjectionFactor: 0.4,
    bezierClampMin: 30.0,
    bezierClampMax: 150.0,
    defaultBodyType: BodyType.uniform,
    taperStartWidth: 2.0,
    taperEndWidth: 2.0,
    widthModulateAmplitude: 1.5,
    widthModulateFrequency: 3.0,
    defaultStartShape: EndpointShapeType.none,
    defaultEndShape: EndpointShapeType.arrow,
    arrowSize: 10.0,
    snakeAmplitude: 20.0,
    snakeFrequency: 3.0,
    snakeObstacleAvoidance: false,
  );
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      recomputeDirty();
    });
  }

  Future<void> recomputeDirty() async {
    if (!_tracker.hasDirtyRelations) return;

    final dirtyIds = _tracker.dirtyRelationIds.toList();
    _log.fine('Recomputing ${dirtyIds.length} dirty relations');

    try {
      final computed = await recompute(dirtyIds: dirtyIds);
      _tracker.updateCache(computed);
    } catch (e) {
      _log.warning('Failed to recompute relations: $e');
    }
  }

  Future<List<ComputedRelation>> recompute({
    List<String>? dirtyIds,
  }) async {
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

  void onInitialLoad({
    required Iterable<UiRelation> relations,
    required Map<String, NodeViewState> nodeViewStates,
  }) {
    _tracker.clear();
    _tracker.indexRelations(relations, nodeViewStates);
    _tracker.markAllDirty();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _tracker.clear();
  }
}
