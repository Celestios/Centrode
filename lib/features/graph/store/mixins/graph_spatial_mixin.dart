import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import 'graph_store_mixin.dart';

/// Tier 2: Viewport culling and reactive geometry.
mixin GraphSpatialMixin on ChangeNotifier, GraphStoreMixin {
  final SpatialHashGrid spatialGrid = SpatialHashGrid();
  final Map<String, Offset> _lastConfirmedPositions = {};

  void saveConfirmedPosition(String id, Offset pos) =>
      _lastConfirmedPositions[id] = pos;
  Offset? getConfirmedPosition(String id) => _lastConfirmedPositions[id];
  void clearConfirmedPosition(String id) => _lastConfirmedPositions.remove(id);

  /// Rebuilds the spatial index from scratch using a set of nodes.
  /// Triggered during bulk load or major graph resets.
  void reindexAll(Map<String, UiNode> nodes) {
    spatialGrid.clear();
    for (final node in nodes.values) {
      spatialGrid.insert(node.id, node.position);
    }
  }

  void disposeSpatial() {
    _lastConfirmedPositions.clear();
  }
}
