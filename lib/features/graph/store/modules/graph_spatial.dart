import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import '../../models/models.dart';
import '../spatial_index.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Encapsulates viewport culling and reactive geometry.
class GraphSpatial {
  final Logger _log = Logger('GraphSpatial');
  final HierarchicalSpatialIndex spatialIndex = HierarchicalSpatialIndex();
  SpatialHashGrid get spatialGrid => spatialIndex.rootGrid;
  final Map<RawUuid, Offset> _lastConfirmedPositions = {};

  void saveConfirmedPosition(RawUuid id, Offset pos) {
    _log.fine('saveConfirmedPosition id=$id');
    _lastConfirmedPositions[id] = pos;
  }

  Offset? getConfirmedPosition(RawUuid id) => _lastConfirmedPositions[id];

  void clearConfirmedPosition(RawUuid id) {
    _log.fine('clearConfirmedPosition id=$id');
    _lastConfirmedPositions.remove(id);
  }

  /// Rebuilds the spatial index from scratch using a set of nodes.
  /// Triggered during bulk load or major graph resets.
  void reindexAll(Map<RawUuid, UiNode> nodes) {
    _log.info('reindexAll: reindexing ${nodes.length} nodes');
    spatialIndex.clear();
    for (final node in nodes.values) {
      spatialIndex.insertNode(node.id, node.parentContainerId, node.position, node.size);
    }
  }

  void dispose() {
    _lastConfirmedPositions.clear();
  }
}
