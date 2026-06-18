import 'dart:ui';

class _CellKey {
  final int x;
  final int y;

  const _CellKey(this.x, this.y);

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CellKey && x == other.x && y == other.y;
}

class _NodeEntry {
  final String nodeId;
  Rect rect;

  _NodeEntry(this.nodeId, this.rect);
}

class GridHash {
  final double cellSize;
  final Map<_CellKey, List<_NodeEntry>> _cells = {};
  final Map<String, _NodeEntry> _entries = {};

  GridHash({this.cellSize = 80.0});

  void insert(String nodeId, Rect rect) {
    final entry = _NodeEntry(nodeId, rect);
    _entries[nodeId] = entry;
    _insertIntoCells(entry);
  }

  void remove(String nodeId) {
    final entry = _entries.remove(nodeId);
    if (entry != null) {
      _removeFromCells(entry);
    }
  }

  void update(String nodeId, Rect newRect) {
    final entry = _entries[nodeId];
    if (entry == null) {
      insert(nodeId, newRect);
      return;
    }
    _removeFromCells(entry);
    entry.rect = newRect;
    _insertIntoCells(entry);
  }

  List<String> query(Offset point) {
    final cx = (point.dx / cellSize).floor();
    final cy = (point.dy / cellSize).floor();
    final result = <String>[];

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final key = _CellKey(cx + dx, cy + dy);
        final cell = _cells[key];
        if (cell != null) {
          for (final entry in cell) {
            if (entry.rect.contains(point)) {
              result.add(entry.nodeId);
            }
          }
        }
      }
    }

    return result;
  }

  void clear() {
    _cells.clear();
    _entries.clear();
  }

  void _insertIntoCells(_NodeEntry entry) {
    final x0 = (entry.rect.left / cellSize).floor();
    final y0 = (entry.rect.top / cellSize).floor();
    final x1 = (entry.rect.right / cellSize).floor();
    final y1 = (entry.rect.bottom / cellSize).floor();

    for (int x = x0; x <= x1; x++) {
      for (int y = y0; y <= y1; y++) {
        final key = _CellKey(x, y);
        _cells.putIfAbsent(key, () => []).add(entry);
      }
    }
  }

  void _removeFromCells(_NodeEntry entry) {
    final x0 = (entry.rect.left / cellSize).floor();
    final y0 = (entry.rect.top / cellSize).floor();
    final x1 = (entry.rect.right / cellSize).floor();
    final y1 = (entry.rect.bottom / cellSize).floor();

    for (int x = x0; x <= x1; x++) {
      for (int y = y0; y <= y1; y++) {
        final key = _CellKey(x, y);
        final cell = _cells[key];
        if (cell != null) {
          cell.remove(entry);
          if (cell.isEmpty) {
            _cells.remove(key);
          }
        }
      }
    }
  }
}
