import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'mixins/graph_spatial_mixin.dart'; // Adjust path if needed for SpatialHashGrid
import '../presentation/view_state.dart';

/// Read-only domain interface enforcing CQRS.
/// Passive UI widgets should consume this instead of GraphDataController
/// to physically prevent accidental state mutations.
abstract interface class GraphDataQuery implements Listenable {
  bool get isLoading;
  String? get errorMessage;
  SpatialHashGrid get spatialGrid; // or spatialHash based on your alias
  Map<String, NodeViewState> get viewStates; // or allNodeViewStates
  Map<String, UiNode> get nodeLookup;
  Map<String, UiRelation> get relationLookup;
  Iterable<UiRelation> get relations;
  MovementNotifier get movementNotifier;
}
