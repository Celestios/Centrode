import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../store/graph_data_controller.dart';
import '../store/graph_data_query.dart';
import '../store/spatial_index.dart';

class GraphPresentationNotifier extends ChangeNotifier implements GraphDataQuery {
  final GraphDataController controller;
  StreamSubscription<GraphEntityUpdate>? _subscription;

  GraphPresentationNotifier(this.controller) {
    _subscription = controller.onEntityUpdate.listen((_) {
      notifyListeners();
    });
  }

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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
