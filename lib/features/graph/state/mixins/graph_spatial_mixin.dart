import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../domain/models.dart';
import 'graph_store_mixin.dart';

class MovementNotifier extends ChangeNotifier {
  void pulse() => notifyListeners();
}

/// Tier 2: Viewport culling and reactive geometry.
mixin GraphSpatialMixin on ChangeNotifier, GraphStoreMixin {
  final SpatialHashGrid spatialGrid = SpatialHashGrid();
  final Map<String, NodeViewState> viewStates = {};
  final MovementNotifier movementNotifier = MovementNotifier();
  final Map<String, Offset> _lastConfirmedPositions = {};

  void syncViewStates() {
    final currentIds = nodeLookup.keys.toSet();
    final removedIds = viewStates.keys.toSet().difference(currentIds);

    for (final id in removedIds) {
      viewStates[id]?.dispose();
      viewStates.remove(id);
      _lastConfirmedPositions.remove(id);
    }

    for (final entry in nodeLookup.entries) {
      if (!viewStates.containsKey(entry.key)) {
        viewStates[entry.key] = NodeViewState(entry.value);
      }
    }
  }

  void saveConfirmedPosition(String id, Offset pos) =>
      _lastConfirmedPositions[id] = pos;
  Offset? getConfirmedPosition(String id) => _lastConfirmedPositions[id];
  void clearConfirmedPosition(String id) => _lastConfirmedPositions.remove(id);

  void disposeSpatial() {
    for (final vs in viewStates.values) {
      vs.dispose();
    }
    viewStates.clear();
    _lastConfirmedPositions.clear();
    movementNotifier.dispose();
  }
}
