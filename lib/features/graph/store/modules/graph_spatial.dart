import 'dart:ui';
import 'package:mycelium/infrastructure/telemetry/logging.dart';
import '../../models/models.dart';
import '../spatial_index.dart';

/// Encapsulates viewport culling and reactive geometry.
class GraphSpatial {
  final Logger _log = Logger('GraphSpatial');
  final SpatialHashGrid spatialGrid = SpatialHashGrid();
  final Map<String, Offset> _lastConfirmedPositions = {};

  void saveConfirmedPosition(String id, Offset pos) {
    _log.fine('saveConfirmedPosition id=$id');
    _lastConfirmedPositions[id] = pos;
  }

  Offset? getConfirmedPosition(String id) => _lastConfirmedPositions[id];

  void clearConfirmedPosition(String id) {
    _log.fine('clearConfirmedPosition id=$id');
    _lastConfirmedPositions.remove(id);
  }

  /// Rebuilds the spatial index from scratch using a set of nodes.
  /// Triggered during bulk load or major graph resets.
  void reindexAll(Map<String, UiNode> nodes) {
    _log.info('reindexAll: reindexing ${nodes.length} nodes');
    spatialGrid.clear();
    for (final node in nodes.values) {
      spatialGrid.insert(node.id, node.position);
    }
  }

  void dispose() {
    _lastConfirmedPositions.clear();
  }
}
