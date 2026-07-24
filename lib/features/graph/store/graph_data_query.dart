import 'dart:async';
import '../models/models.dart';
import 'spatial_index.dart';
import 'relation_engine_state.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

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
  final RawUuid? id;
  final String tableName;
  final GraphUpdateType type;
  final dynamic payload;

  GraphEntityUpdate({
    this.id,
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
  SpatialHashGrid get spatialGrid;
  Map<RawUuid, UiNode> get nodeLookup;
  Map<RawUuid, UiRelation> get relationLookup;
  Iterable<UiRelation> get relations;
  BoundingBox get canvasBounds;
  RelationEngineState get relationEngine;
  Stream<GraphEntityUpdate> get onEntityUpdate;
}
