import 'dart:math' as math;

/// Grid cell coordinate used by the palette region-layout algorithms.
class _PaletteGridCoord {
  final int x;
  final int y;
  const _PaletteGridCoord(this.x, this.y);
}

/// 4-connected growth directions.
const List<_PaletteGridCoord> _kGrowDirs = [
  _PaletteGridCoord(1, 0),
  _PaletteGridCoord(-1, 0),
  _PaletteGridCoord(0, 1),
  _PaletteGridCoord(0, -1),
];

/// Samples [count] distinct seed cells on *unlocked* space (cells where
/// [fixed] is -1) that are spread apart (Manhattan separation) so no region
/// is born starved in a corner.
List<_PaletteGridCoord> _sampleSeeds(
  math.Random rand,
  List<List<int>> fixed,
  int count,
  int cols,
  int rows,
) {
  const minSep = 3;
  final picks = <_PaletteGridCoord>[];
  var guard = 0;
  while (picks.length < count && guard++ < 600) {
    final x = rand.nextInt(cols);
    final y = rand.nextInt(rows);
    if (fixed[x][y] != -1) continue;
    var ok = true;
    for (final p in picks) {
      if ((p.x - x).abs() + (p.y - y).abs() < minSep) {
        ok = false;
        break;
      }
    }
    if (ok) picks.add(_PaletteGridCoord(x, y));
  }
  while (picks.length < count) {
    var placed = false;
    for (int c = 0; c < cols && !placed; c++) {
      for (int r = 0; r < rows && !placed; r++) {
        if (fixed[c][r] == -1) {
          picks.add(_PaletteGridCoord(c, r));
          placed = true;
        }
      }
    }
    if (!placed) break;
  }
  return picks;
}

/// Multi-source BFS (grassfire) Voronoi assignment on the *unlocked* cells.
/// Locked cells (carried in [fixed] with their color index) act as walls:
/// they are preserved as-is and never overwritten or grown into. Any unlocked
/// cell the BFS cannot reach (enclosed by locks) falls back to its nearest seed.
List<List<int>> _assignVoronoi(
  List<_PaletteGridCoord> seeds,
  List<int> colorForSeed,
  List<List<int>> fixed,
  int cols,
  int rows,
) {
  final grid = List.generate(cols, (c) => List<int>.from(fixed[c]));
  final queue = <_PaletteGridCoord>[];
  for (int j = 0; j < seeds.length; j++) {
    final s = seeds[j];
    if (grid[s.x][s.y] == -1) {
      grid[s.x][s.y] = colorForSeed[j];
      queue.add(s);
    }
  }
  var head = 0;
  while (head < queue.length) {
    final cur = queue[head++];
    final color = grid[cur.x][cur.y];
    for (final d in _kGrowDirs) {
      final nc = cur.x + d.x;
      final nr = cur.y + d.y;
      if (nc >= 0 && nc < cols && nr >= 0 && nr < rows && grid[nc][nr] == -1) {
        grid[nc][nr] = color;
        queue.add(_PaletteGridCoord(nc, nr));
      }
    }
  }

  for (int c = 0; c < cols; c++) {
    for (int r = 0; r < rows; r++) {
      if (grid[c][r] != -1) continue;
      var bestColor = colorForSeed[0];
      var bestDist = double.infinity;
      for (int j = 0; j < seeds.length; j++) {
        final s = seeds[j];
        final dd = math.pow(c - s.x, 2) + math.pow(r - s.y, 2);
        if (dd < bestDist) {
          bestDist = dd.toDouble();
          bestColor = colorForSeed[j];
        }
      }
      grid[c][r] = bestColor;
    }
  }
  return grid;
}

/// Generates the 5-color interlocking region grid.
///
/// Uses a seed-sampled, multi-source BFS Voronoi assignment that guarantees
/// contiguous, convex-ish, balanced pieces with no tendrils. When [lockedSlots]
/// marks colors whose regions already exist in [previousGrid], those exact cell
/// sets are frozen (treated as walls) and only the unlocked cells are
/// re-partitioned — so locking a color freezes both its hue and its shape.
List<List<int>> generatePaletteGrid({
  required int cols,
  required int rows,
  required int colorCount,
  required List<bool> lockedSlots,
  List<List<int>>? previousGrid,
}) {
  final rand = math.Random();

  // Capture currently locked regions so their exact shape is preserved.
  final fixed = List.generate(cols, (_) => List.filled(rows, -1));
  final lockedColors = <int>[];
  if (previousGrid != null) {
    for (int i = 0; i < colorCount; i++) {
      if (!lockedSlots[i]) continue;
      var found = false;
      for (int c = 0; c < cols; c++) {
        for (int r = 0; r < rows; r++) {
          if (previousGrid[c][r] == i) {
            fixed[c][r] = i;
            found = true;
          }
        }
      }
      if (found) lockedColors.add(i);
    }
  }

  final unlockedColors = <int>[
    for (int i = 0; i < colorCount; i++)
      if (!lockedColors.contains(i)) i,
  ];

  // Nothing to regenerate (all colors locked) — keep the current grid.
  if (unlockedColors.isEmpty) {
    return List.generate(cols, (c) => List<int>.from(fixed[c]));
  }

  // Try several seed layouts and keep the most balanced one (size range +
  // variance), requiring a sane minimum size per color.
  List<_PaletteGridCoord>? bestSeeds;
  List<int>? bestColorForSeed;
  List<List<int>>? bestGrid;
  var bestScore = double.infinity;

  for (int attempt = 0; attempt < 30; attempt++) {
    final seeds = _sampleSeeds(rand, fixed, unlockedColors.length, cols, rows);
    if (seeds.length < unlockedColors.length) continue;
    final grid = _assignVoronoi(seeds, unlockedColors, fixed, cols, rows);

    final sizes = List.filled(unlockedColors.length, 0);
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final v = grid[c][r];
        if (v >= 0 && lockedColors.contains(v)) continue;
        if (v >= 0) sizes[unlockedColors.indexOf(v)]++;
      }
    }

    var minS = sizes[0];
    var maxS = sizes[0];
    var sum = 0;
    for (final s in sizes) {
      if (s < minS) minS = s;
      if (s > maxS) maxS = s;
      sum += s;
    }
    final mean = sum / unlockedColors.length;
    var variance = 0.0;
    for (final s in sizes) {
      variance += (s - mean) * (s - mean);
    }
    variance /= unlockedColors.length;

    final score = (maxS - minS).toDouble() + variance * 0.5;
    if (minS >= 4 && score < bestScore) {
      bestScore = score;
      bestSeeds = seeds;
      bestColorForSeed = unlockedColors;
      bestGrid = grid;
    }
  }

  if (bestSeeds == null) {
    bestSeeds = _sampleSeeds(rand, fixed, unlockedColors.length, cols, rows);
    bestColorForSeed = unlockedColors;
    bestGrid = _assignVoronoi(bestSeeds, bestColorForSeed, fixed, cols, rows);
  }

  return bestGrid!;
}
