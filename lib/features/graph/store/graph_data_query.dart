import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show BoundingBox;
import '../models/models.dart';

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
  reset
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
abstract interface class GraphDataQuery implements Listenable {
  bool get isLoading;
  String? get errorMessage;
  SpatialHashGrid get spatialGrid; // or spatialHash based on your alias
  Map<String, UiNode> get nodeLookup;
  Map<String, UiRelation> get relationLookup;
  Iterable<UiRelation> get relations;
  ValueNotifier<BoundingBox> get canvasBounds;
  Stream<GraphEntityUpdate> get onEntityUpdate;
}


