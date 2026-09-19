import 'dart:ui' show Offset, Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/geometry/polyomino.dart';

void main() {
  group('computeRegionOutlines — marching squares boundary tracing', () {
    test('single-cell region produces a closed path', () {
      final grid = [
        [0, -1, -1],
        [-1, -1, -1],
        [-1, -1, -1],
      ];
      final paths = computeRegionOutlines(grid, 3, 3, 1, const Size(300, 300));
      expect(paths.length, equals(1));
      expect(paths[0]..getBounds(), isNot(equals(Rect.zero)));
    });

    test('multi-cell contiguous region traces a single connected boundary', () {
      final grid = [
        [0, 0, 0],
        [0, 0, 0],
        [-1, -1, -1],
      ];
      final paths = computeRegionOutlines(grid, 3, 3, 1, const Size(300, 300));
      expect(paths.length, equals(1));
      final bounds = paths[0].getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('two separate regions produce two distinct paths', () {
      final grid = [
        [0, -1, 1],
        [-1, -1, 1],
        [-1, -1, -1],
      ];
      final paths = computeRegionOutlines(grid, 3, 3, 2, const Size(300, 300));
      expect(paths.length, equals(2));
      expect(paths[0].getBounds(), isNot(equals(paths[1].getBounds())));
    });

    test('empty region returns empty path', () {
      final grid = [
        [-1, -1, -1],
        [-1, -1, -1],
        [-1, -1, -1],
      ];
      final paths = computeRegionOutlines(grid, 3, 3, 1, const Size(300, 300));
      expect(paths.length, equals(1));
      expect(paths[0].getBounds(), equals(Rect.zero));
    });

    test('donut shape traces boundary including hole', () {
      final grid = [
        [0, 0, 0, 0],
        [0, -1, -1, 0],
        [0, -1, -1, 0],
        [0, 0, 0, 0],
      ];
      final paths = computeRegionOutlines(grid, 4, 4, 1, const Size(400, 400));
      expect(paths.length, equals(1));
      final bounds = paths[0].getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('L-shaped region boundary is non-empty', () {
      final grid = [
        [0, 0, -1],
        [0, -1, -1],
        [0, -1, -1],
      ];
      final paths = computeRegionOutlines(grid, 3, 3, 1, const Size(300, 300));
      expect(paths.length, equals(1));
      expect(paths[0].getBounds(), isNot(equals(Rect.zero)));
    });
  });

  group('computeRegionAnchors — centroid calculation invariants', () {
    test('centroid lies within region bounds for a solid block', () {
      final grid = [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0],
      ];
      final anchors = computeRegionAnchors(grid, 3, 3, 1, const Size(300, 300));
      expect(anchors.length, equals(1));
      final anchor = anchors[0];
      expect(anchor.dx, greaterThanOrEqualTo(0));
      expect(anchor.dx, lessThanOrEqualTo(300));
      expect(anchor.dy, greaterThanOrEqualTo(0));
      expect(anchor.dy, lessThanOrEqualTo(300));
    });

    test('centroid of single cell is at cell center', () {
      final grid = [
        [0, -1, -1],
        [-1, -1, -1],
        [-1, -1, -1],
      ];
      final anchors = computeRegionAnchors(grid, 3, 3, 1, const Size(300, 300));
      expect(anchors.length, equals(1));
      final anchor = anchors[0];
      // Cell (0,0) center in 300x300 grid with 3 cols/rows = (50, 50)
      expect(anchor.dx, closeTo(50, 30));
      expect(anchor.dy, closeTo(50, 30));
    });

    test('two regions each get their own centroid within bounds', () {
      final grid = [
        [0, 0, -1],
        [0, 0, -1],
        [-1, -1, 1],
      ];
      final anchors = computeRegionAnchors(grid, 3, 3, 2, const Size(300, 300));
      expect(anchors.length, equals(2));
      for (final anchor in anchors) {
        expect(anchor.dx, inInclusiveRange(0, 300));
        expect(anchor.dy, inInclusiveRange(0, 300));
      }
    });

    test('empty region returns fallback center', () {
      final grid = [
        [-1, -1, -1],
        [-1, -1, -1],
        [-1, -1, -1],
      ];
      final anchors = computeRegionAnchors(grid, 3, 3, 1, const Size(300, 300));
      expect(anchors.length, equals(1));
      // Falls back to grid center
      expect(anchors[0].dx, closeTo(150, 1));
      expect(anchors[0].dy, closeTo(150, 1));
    });

    test('donut region centroid lies within bounds', () {
      final grid = [
        [0, 0, 0, 0],
        [0, -1, -1, 0],
        [0, -1, -1, 0],
        [0, 0, 0, 0],
      ];
      final anchors = computeRegionAnchors(grid, 4, 4, 1, const Size(400, 400));
      expect(anchors.length, equals(1));
      final anchor = anchors[0];
      expect(anchor.dx, inInclusiveRange(0, 400));
      expect(anchor.dy, inInclusiveRange(0, 400));
    });
  });

  group('insetPolygon', () {
    test('inset of triangle produces three points', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(50, 100),
      ];
      final result = insetPolygon(pts, 5);
      expect(result.length, equals(3));
    });

    test('negative inset (outset) expands the polygon', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(0, 100),
      ];
      final inset = insetPolygon(pts, 5);
      final outset = insetPolygon(pts, -5);
      // Outset should produce a larger bounding box
      final insetBounds = _boundingBox(inset);
      final outsetBounds = _boundingBox(outset);
      expect(outsetBounds.width, greaterThanOrEqualTo(insetBounds.width));
      expect(outsetBounds.height, greaterThanOrEqualTo(insetBounds.height));
    });
  });

  group('roundedPath', () {
    test('rounded path of triangle is a valid closed path', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(50, 100),
      ];
      final path = roundedPath(pts, 10);
      expect(path.getBounds(), isNot(equals(Rect.zero)));
    });

    test('rounded path of fewer than 3 points returns empty path', () {
      final pts = [const Offset(0, 0), const Offset(100, 0)];
      final path = roundedPath(pts, 10);
      expect(path.getBounds(), equals(Rect.zero));
    });
  });
}

Rect _boundingBox(List<Offset> pts) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final p in pts) {
    if (p.dx < minX) minX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
