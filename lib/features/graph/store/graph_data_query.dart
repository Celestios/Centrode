import 'dart:async';
import '../models/models.dart';
import 'spatial_index.dart';

enum GraphUpdateType {
  position,
  size,
  text,
  style,
  expansion,
  nodeAdded,
  nodeDeleted,
  relationAdded,
  relationDeleted,
  relationLayout,
  tags,
  comments,
  reset,
  boundary,
}

class GraphEntityUpdate {
  final String id;
  final String tableName;
  final GraphUpdateType type;
  final dynamic payload;

  GraphEntityUpdate({
    required this.id,
    required this.tableName,
    required this.type,
    this.payload,
  });
}

/// Read-only domain interface enforcing CQRS.
/// Passive UI widgets should consume this instead of GraphDataController
/// to physically prevent accidental state mutations.
abstract interface class GraphDataQuery {
  bool get isLoading;
  String? get errorMessage;
  SpatialHashGrid get spatialGrid; // or spatialHash based on your alias
  Map<String, UiNode> get nodeLookup;
  Map<String, UiRelation> get relationLookup;
  Iterable<UiRelation> get relations;
  BoundingBox get canvasBounds;
  Stream<GraphEntityUpdate> get onEntityUpdate;
}
