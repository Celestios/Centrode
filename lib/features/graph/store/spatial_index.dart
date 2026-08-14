import 'dart:math';
import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/graph_node.dart';

// -----------------------------------------------------------------------------
// Spatial Hash Grid for O(1) Lookups
// -----------------------------------------------------------------------------

/// Provides O(1) spatial lookups and updates for viewport culling.
/// Divides the canvas into chunks for efficient spatial queries.
class SpatialHashGrid {
  final double chunkSize;
  final Map<Point<int>, Set<RawUuid>> _grid = {};
  final Map<RawUuid, Set<Point<int>>> _nodeChunks = {};
  final Logger _log = Logger('SpatialHashGrid');

  SpatialHashGrid({this.chunkSize = 1000.0});

  /// Returns the chunk coordinates for a given position.
  Point<int> getChunk(Offset position) =>
      Point(position.dx ~/ chunkSize, position.dy ~/ chunkSize);

  Set<Point<int>> _getChunksForRect(Rect rect) {
    final Set<Point<int>> chunks = {};
    final int minX = rect.left ~/ chunkSize;
    final int maxX = rect.right ~/ chunkSize;
    final int minY = rect.top ~/ chunkSize;
    final int maxY = rect.bottom ~/ chunkSize;
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        chunks.add(Point(x, y));
      }
    }
    return chunks;
  }

  /// Inserts a node ID at the specified position and optional size.
  void insert(RawUuid nodeId, Offset position, [Size size = Size.zero]) {
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      max(0.0, size.width),
      max(0.0, size.height),
    );
    final chunks = _getChunksForRect(rect);
    _nodeChunks[nodeId] = chunks;
    for (final chunk in chunks) {
      _grid.putIfAbsent(chunk, () => {}).add(nodeId);
    }
  }

  /// Updates a node's position and optional size in the grid.
  void update(RawUuid nodeId, Offset oldPos, Offset newPos, [Size size = Size.zero]) {
    final oldChunks = _nodeChunks[nodeId] ?? {getChunk(oldPos)};
    final newRect = Rect.fromLTWH(
      newPos.dx,
      newPos.dy,
      max(0.0, size.width),
      max(0.0, size.height),
    );
    final newChunks = _getChunksForRect(newRect);

    for (final oldChunk in oldChunks) {
      if (!newChunks.contains(oldChunk)) {
        _grid[oldChunk]?.remove(nodeId);
      }
    }
    for (final newChunk in newChunks) {
      if (!oldChunks.contains(newChunk)) {
        _grid.putIfAbsent(newChunk, () => {}).add(nodeId);
      }
    }
    _nodeChunks[nodeId] = newChunks;
  }

  /// Removes a node from the grid.
  void remove(RawUuid nodeId, Offset position) {
    final chunks = _nodeChunks.remove(nodeId) ?? {getChunk(position)};
    for (final chunk in chunks) {
      _grid[chunk]?.remove(nodeId);
    }
  }

  /// Queries all node IDs within the specified rectangular bounds.
  Set<RawUuid> queryRect(Rect bounds) {
    final Set<RawUuid> visible = {};
    final int minX = bounds.left ~/ chunkSize;
    final int maxX = bounds.right ~/ chunkSize;
    final int minY = bounds.top ~/ chunkSize;
    final int maxY = bounds.bottom ~/ chunkSize;

    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        final chunk = _grid[Point(x, y)];
        if (chunk != null) visible.addAll(chunk);
      }
    }

    return visible;
  }

  /// Returns node IDs in the chunk containing [point] plus all 8 neighbors.
  /// Used for hover hit-testing where nodes may extend into adjacent chunks.
  Set<RawUuid> queryPoint(Offset point) {
    final center = getChunk(point);
    final Set<RawUuid> result = {};
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final chunk = _grid[Point(center.x + dx, center.y + dy)];
        if (chunk != null) result.addAll(chunk);
      }
    }
    return result;
  }

  /// Clears all entries from the grid.
  void clear() {
    _grid.clear();
    _nodeChunks.clear();
    _log.info('SPATIAL: Grid cleared (Rehash/Reset triggered).');
  }
}

/// Manages top-level and container-scoped spatial hash grids for hierarchical viewport culling.
class HierarchicalSpatialIndex {
  final SpatialHashGrid _rootGrid = SpatialHashGrid();
  final Map<RawUuid, SpatialHashGrid> _containerGrids = {};

  SpatialHashGrid get rootGrid => _rootGrid;

  void insertNode(RawUuid nodeId, RawUuid? parentContainerId, Offset position, [Size size = Size.zero]) {
    if (parentContainerId == null) {
      _rootGrid.insert(nodeId, position, size);
    } else {
      final grid = _containerGrids.putIfAbsent(parentContainerId, () => SpatialHashGrid());
      grid.insert(nodeId, position, size);
    }
  }

  void updateNode(RawUuid nodeId, RawUuid? parentContainerId, Offset oldPos, Offset newPos, [Size size = Size.zero]) {
    final grid = parentContainerId == null ? _rootGrid : _containerGrids[parentContainerId];
    grid?.update(nodeId, oldPos, newPos, size);
  }

  void removeNode(RawUuid nodeId, RawUuid? parentContainerId, Offset position) {
    final grid = parentContainerId == null ? _rootGrid : _containerGrids[parentContainerId];
    grid?.remove(nodeId, position);
    _containerGrids.remove(nodeId);
  }

  void migrateNodeSpatialGrid(
    RawUuid nodeId,
    RawUuid? oldParentId,
    RawUuid? newParentId,
    Offset oldLocalPos,
    Offset newLocalPos, [
    Size size = Size.zero,
  ]) {
    removeNode(nodeId, oldParentId, oldLocalPos);
    insertNode(nodeId, newParentId, newLocalPos, size);
  }

  Set<RawUuid> queryViewport(Rect rootViewportRect, double cameraScale, Map<RawUuid, UiNode> nodes) {
    final Set<RawUuid> visibleNodeIds = {};

    final candidates = _rootGrid.queryRect(rootViewportRect);

    for (final id in candidates) {
      final node = nodes[id];
      if (node == null) continue;

      visibleNodeIds.add(id);

      if (node is ContainerUiNode && !node.isClosed) {
        _queryContainerScope(node, rootViewportRect, nodes, visibleNodeIds);
      }
    }

    return visibleNodeIds;
  }

  void _queryContainerScope(
    ContainerUiNode container,
    Rect parentViewportRect,
    Map<RawUuid, UiNode> nodes,
    Set<RawUuid> visibleNodeIds,
  ) {
    final grid = _containerGrids[container.id];
    if (grid == null) return;

    final localViewportRect = parentViewportRect.shift(-container.position);
    final childCandidates = grid.queryRect(localViewportRect);

    for (final childId in childCandidates) {
      final child = nodes[childId];
      if (child == null) continue;

      visibleNodeIds.add(childId);

      if (child is ContainerUiNode && !child.isClosed) {
        _queryContainerScope(child, localViewportRect, nodes, visibleNodeIds);
      }
    }
  }

  void clear() {
    _rootGrid.clear();
    _containerGrids.clear();
  }
}
