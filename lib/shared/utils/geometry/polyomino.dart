import 'dart:ui' show Offset, Path, Size;

/// Grid cell coordinate used by the polyomino boundary tracing.
class _PolyGridCoord {
  final int x;
  final int y;
  const _PolyGridCoord(this.x, this.y);
}

/// Unit vectors (N, E, S, W) — order must match the direction encoding used by
/// [_hasOutgoing] / [_traceRegionBoundary].
const List<Offset> _kDirVec = [
  Offset(0, -1),
  Offset(1, 0),
  Offset(0, 1),
  Offset(-1, 0),
];

bool _regionFilled(List<List<int>> grid, int cols, int rows, int colorIdx, int x, int y) =>
    x >= 0 && x < cols && y >= 0 && y < rows && grid[x][y] == colorIdx;

/// Marching-squares style: is `dir` an outgoing edge of the region between the
/// 2x2 cell block anchored at (cx-1, cy-1) and (cx, cy)? 1 = fill, 0 = empty.
bool _hasOutgoing(
  List<List<int>> grid,
  int cols,
  int rows,
  int colorIdx,
  int cx,
  int cy,
  int dir,
) {
  final a = _regionFilled(grid, cols, rows, colorIdx, cx - 1, cy - 1);
  final b = _regionFilled(grid, cols, rows, colorIdx, cx, cy - 1);
  final c = _regionFilled(grid, cols, rows, colorIdx, cx - 1, cy);
  final d = _regionFilled(grid, cols, rows, colorIdx, cx, cy);
  switch (dir) {
    case 0:
      return b && !a;
    case 1:
      return d && !b;
    case 2:
      return c != d;
    case 3:
      return a && !c;
    default:
      return false;
  }
}

/// Traces the closed boundary of a color region as grid-corner coordinates,
/// handling holes and concavities. Returns `[]` if the region is empty.
List<_PolyGridCoord> _traceRegionBoundary(
  List<List<int>> grid,
  int cols,
  int rows,
  int colorIdx,
) {
  int sx = 0, sy = 0, sdir = 1;
  bool found = false;
  outer:
  for (int cy = 0; cy <= rows && !found; cy++) {
    for (int cx = 0; cx <= cols; cx++) {
      for (int dir = 1; dir <= 4; dir++) {
        final d = dir % 4;
        if (_hasOutgoing(grid, cols, rows, colorIdx, cx, cy, d)) {
          sx = cx;
          sy = cy;
          sdir = d;
          found = true;
          break outer;
        }
      }
    }
  }
  if (!found) return const [];

  final result = <_PolyGridCoord>[_PolyGridCoord(sx, sy)];
  var curX = sx;
  var curY = sy;
  var dir = sdir;
  var guard = 0;
  while (guard++ < 10000) {
    final v = _kDirVec[dir];
    final nx = curX + v.dx.toInt();
    final ny = curY + v.dy.toInt();
    final candidates = [(dir + 1) % 4, dir, (dir + 3) % 4, (dir + 2) % 4];
    var chosen = (dir + 2) % 4; // fallback: dead-end, turn around
    for (final cand in candidates) {
      if (_hasOutgoing(grid, cols, rows, colorIdx, nx, ny, cand)) {
        chosen = cand;
        break;
      }
    }
    dir = chosen;
    curX = nx;
    curY = ny;
    if (curX == sx && curY == sy) break;
    result.add(_PolyGridCoord(curX, curY));
  }
  return result;
}

/// Inset/outset a polygon (negative gap = inward), keeping convex corners and
/// miter-joining concave corners, so symmetrical concave shapes keep corners.
List<Offset> insetPolygon(List<Offset> pts, double gap) {
  final n = pts.length;
  if (n < 3) return pts;
  const inward = -1.0;
  final out = <Offset>[];
  for (int i = 0; i < n; i++) {
    final prev = pts[(i - 1 + n) % n];
    final cur = pts[i];
    final next = pts[(i + 1) % n];
    final d1 = cur - prev;
    final d2 = next - cur;
    final len1 = d1.distance;
    final len2 = d2.distance;
    if (len1 == 0 || len2 == 0) {
      out.add(cur);
      continue;
    }
    final n1 = Offset(d1.dy * inward, -d1.dx * inward);
    final n2 = Offset(d2.dy * inward, -d2.dx * inward);
    final miter = Offset(n1.dx / len1 + n2.dx / len2, n1.dy / len1 + n2.dy / len2);
    final ml = miter.distance;
    if (ml == 0) {
      out.add(cur);
      continue;
    }
    out.add(cur + miter * (gap / ml));
  }
  return out;
}

/// Round every corner of the polygon with a quadratic bezier (radius capped to
/// half the edge length), preserving interior layout.
Path roundedPath(List<Offset> pts, double radius) {
  final n = pts.length;
  if (n < 3) return Path();
  final path = Path();
  for (int i = 0; i < n; i++) {
    final cur = pts[i];
    final prev = pts[(i - 1 + n) % n];
    final next = pts[(i + 1) % n];
    final dPrev = cur - prev;
    final dNext = next - cur;
    final lenP = dPrev.distance;
    final lenN = dNext.distance;
    final rP = lenP > 0 ? (radius.clamp(0.0, lenP / 2)) / lenP : 0.0;
    final rN = lenN > 0 ? (radius.clamp(0.0, lenN / 2)) / lenN : 0.0;
    final p1 = cur - dPrev * rP;
    final p2 = cur + dNext * rN;
    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}

/// Computes rounded, gap-inset [Path] outlines for every color region, scaled
/// to [size].
List<Path> computeRegionOutlines(
  List<List<int>> grid,
  int cols,
  int rows,
  int colorCount,
  Size size, {
  double gap = 2.5,
  double radius = 9.0,
}) {
  final cellW = size.width / cols;
  final cellH = size.height / rows;
  return List.generate(colorCount, (colorIdx) {
    final corners = _traceRegionBoundary(grid, cols, rows, colorIdx);
    if (corners.isEmpty) return Path();
    final pts = corners.map((p) => Offset(p.x * cellW, p.y * cellH)).toList();
    final inset = insetPolygon(pts, gap);
    return roundedPath(inset, radius);
  });
}

/// Computes a label anchor for every color region: the pole of inaccessibility
/// (deepest interior cell, via multi-source BFS from boundary), refined by a
/// depth-weighted centroid with outlier trimming so long arms cannot drag the
/// tag to an edge.
List<Offset> computeRegionAnchors(
  List<List<int>> grid,
  int cols,
  int rows,
  int colorCount,
  Size size,
) {
  final cellW = size.width / cols;
  final cellH = size.height / rows;
  const dirs = [
    _PolyGridCoord(1, 0),
    _PolyGridCoord(-1, 0),
    _PolyGridCoord(0, 1),
    _PolyGridCoord(0, -1),
  ];

  return List.generate(colorCount, (colorIdx) {
    var sumX = 0.0;
    var sumY = 0.0;
    var count = 0;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (grid[c][r] == colorIdx) {
          sumX += c + 0.5;
          sumY += r + 0.5;
          count++;
        }
      }
    }
    if (count == 0) {
      return Offset((cols / 2) * cellW, (rows / 2) * cellH);
    }
    final centroidC = sumX / count;
    final centroidR = sumY / count;

    // Multi-source BFS from boundary cells → distance field (pole of inaccessibility).
    final dist = List.generate(cols, (_) => List.filled(rows, -1));
    final queue = <_PolyGridCoord>[];
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (grid[c][r] != colorIdx) continue;
        var isBoundary = false;
        for (final d in dirs) {
          final nc = c + d.x;
          final nr = r + d.y;
          final neighborColor =
              (nc >= 0 && nc < cols && nr >= 0 && nr < rows) ? grid[nc][nr] : -2;
          if (neighborColor != colorIdx) {
            isBoundary = true;
            break;
          }
        }
        if (isBoundary) {
          dist[c][r] = 0;
          queue.add(_PolyGridCoord(c, r));
        }
      }
    }
    var head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      final cd = dist[cur.x][cur.y];
      for (final d in dirs) {
        final nc = cur.x + d.x;
        final nr = cur.y + d.y;
        if (nc >= 0 &&
            nc < cols &&
            nr >= 0 &&
            nr < rows &&
            grid[nc][nr] == colorIdx &&
            dist[nc][nr] == -1) {
          dist[nc][nr] = cd + 1;
          queue.add(_PolyGridCoord(nc, nr));
        }
      }
    }

    // Dijkstra-corrected depth-weighted centroid, with outlier trimming.
    final cells = <_PolyGridCoord>[];
    final depths = <double>[];
    var anyInterior = false;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (grid[c][r] == colorIdx && dist[c][r] >= 0) {
          cells.add(_PolyGridCoord(c, r));
          depths.add(dist[c][r].toDouble());
          if (dist[c][r] > 0) anyInterior = true;
        }
      }
    }
    if (cells.isEmpty) {
      return Offset(centroidC * cellW, centroidR * cellH);
    }

    var cx = centroidC;
    var cy = centroidR;
    for (int pass = 0; pass < 4; pass++) {
      var wx = 0.0;
      var wy = 0.0;
      var wsum = 0.0;
      for (int i = 0; i < cells.length; i++) {
        final w = anyInterior ? (depths[i] + 1.0) : 1.0;
        wx += (cells[i].x + 0.5) * w;
        wy += (cells[i].y + 0.5) * w;
        wsum += w;
      }
      cx = wx / wsum;
      cy = wy / wsum;

      var maxD2 = 0.0;
      final d2 = <double>[];
      for (final cell in cells) {
        final dx = cell.x + 0.5 - cx;
        final dy = cell.y + 0.5 - cy;
        final d = dx * dx + dy * dy;
        d2.add(d);
        if (d > maxD2) maxD2 = d;
      }
      if (maxD2 <= 1.0) break;
      final threshold = maxD2 * 0.6;
      final nextCells = <_PolyGridCoord>[];
      final nextDepths = <double>[];
      for (int i = 0; i < cells.length; i++) {
        if (d2[i] <= threshold) {
          nextCells.add(cells[i]);
          nextDepths.add(depths[i]);
        }
      }
      if (nextCells.length <= 1) break;
      cells
        ..clear()
        ..addAll(nextCells);
      depths
        ..clear()
        ..addAll(nextDepths);
    }

    return Offset(cx * cellW, cy * cellH);
  });
}
