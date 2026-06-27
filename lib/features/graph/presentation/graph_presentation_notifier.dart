import 'dart:async';
import 'package:mycelium/shared/logging.dart';
import '../models/models.dart';
import '../store/graph_data_controller.dart';
import '../store/graph_data_query.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';

/// Read-only facade over GraphDataController.
/// Does NOT subscribe to entity updates - use NodeRenderState for reactive UI.
class GraphPresentationNotifier implements GraphDataQuery {
  final Logger _log = Logger('GraphPresentationNotifier');
  final GraphDataController controller;

  GraphPresentationNotifier(this.controller) {
    _log.info('GraphPresentationNotifier created (static facade)');
  }

  @override
  RelationEngineState get relationEngine => controller.relationEngine;

  @override
  bool get isLoading => controller.isLoading;

  @override
  String? get errorMessage => controller.errorMessage;

  @override
  SpatialHashGrid get spatialGrid => controller.spatialGrid;

  @override
  Map<String, UiNode> get nodeLookup => controller.nodeLookup;

  @override
  Map<String, UiRelation> get relationLookup => controller.relationLookup;

  @override
  Iterable<UiRelation> get relations => controller.relations;

  @override
  BoundingBox get canvasBounds => controller.canvasBounds;

  @override
  Stream<GraphEntityUpdate> get onEntityUpdate => controller.onEntityUpdate;

  void dispose() {
    _log.info('GraphPresentationNotifier disposed');
  }
}
