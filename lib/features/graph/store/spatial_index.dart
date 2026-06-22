import 'dart:math';
import 'dart:ui';
import 'package:mycelium/shared/logging.dart';

// -----------------------------------------------------------------------------
// Spatial Hash Grid for O(1) Lookups
// -----------------------------------------------------------------------------

/// Provides O(1) spatial lookups and updates for viewport culling.
/// Divides the canvas into chunks for efficient spatial queries.
class SpatialHashGrid {
  final double chunkSize;
  final Map<Point<int>, Set<String>> _grid = {};
  final Logger _log = Logger('SpatialHashGrid');

  SpatialHashGrid({this.chunkSize = 1000.0});

  /// Returns the chunk coordinates for a given position.
  Point<int> getChunk(Offset position) =>
      Point(position.dx ~/ chunkSize, position.dy ~/ chunkSize);

  /// Inserts a node ID at the specified position.
  void insert(String nodeId, Offset position) {
    _grid.putIfAbsent(getChunk(position), () => {}).add(nodeId);
  }

  /// Updates a node's position in the grid.
  /// Only modifies the grid if the node moves to a different chunk.
  void update(String nodeId, Offset oldPos, Offset newPos) {
    final oldChunk = getChunk(oldPos);
    final newChunk = getChunk(newPos);
    if (oldChunk != newChunk) {
      // [NEW] Track chunk transitions to debug ghost nodes
      _log.fine('SPATIAL: $nodeId moving chunk $oldChunk -> $newChunk');
      _grid[oldChunk]?.remove(nodeId);
      _grid.putIfAbsent(newChunk, () => {}).add(nodeId);
    }
  }

  /// Removes a node from the grid.
  void remove(String nodeId, Offset position) {
    _grid[getChunk(position)]?.remove(nodeId);
  }

  /// Queries all node IDs within the specified rectangular bounds.
  Set<String> queryRect(Rect bounds) {
    final Set<String> visible = {};
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
  Set<String> queryPoint(Offset point) {
    final center = getChunk(point);
    final Set<String> result = {};
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
    _log.info(
      'SPATIAL: Grid cleared (Rehash/Reset triggered).',
    ); // [NEW] Track structural resets
  }
}
