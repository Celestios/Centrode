import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/palette_layout.dart';

void main() {
  group('generatePaletteGrid', () {
    test('output dimensions match grid specification', () {
      final grid = generatePaletteGrid(
        cols: 10,
        rows: 8,
        colorCount: 5,
        lockedSlots: List.filled(5, false),
      );
      expect(grid.length, equals(10));
      for (final col in grid) {
        expect(col.length, equals(8));
      }
    });

    test('all grid cells are assigned to a valid partition index', () {
      final grid = generatePaletteGrid(
        cols: 12,
        rows: 8,
        colorCount: 5,
        lockedSlots: List.filled(5, false),
      );
      for (int c = 0; c < 12; c++) {
        for (int r = 0; r < 8; r++) {
          expect(grid[c][r], inInclusiveRange(0, 4));
        }
      }
    });

    test('zero orphan cells — every cell assigned', () {
      final grid = generatePaletteGrid(
        cols: 12,
        rows: 8,
        colorCount: 5,
        lockedSlots: List.filled(5, false),
      );
      var totalCells = 0;
      for (int c = 0; c < 12; c++) {
        for (int r = 0; r < 8; r++) {
          expect(grid[c][r], greaterThanOrEqualTo(0));
          totalCells++;
        }
      }
      expect(totalCells, equals(96));
    });

    test('locked slot preservation invariant — locked region cells unchanged', () {
      // Generate an initial grid.
      final initial = generatePaletteGrid(
        cols: 8,
        rows: 6,
        colorCount: 3,
        lockedSlots: List.filled(3, false),
      );

      // Lock color 0 and regenerate.
      final locked = generatePaletteGrid(
        cols: 8,
        rows: 6,
        colorCount: 3,
        lockedSlots: [true, false, false],
        previousGrid: initial,
      );

      // Every cell that was color 0 in initial must still be color 0 in locked.
      for (int c = 0; c < 8; c++) {
        for (int r = 0; r < 6; r++) {
          if (initial[c][r] == 0) {
            expect(locked[c][r], equals(0));
          }
        }
      }
    });

    test('all colors appear at least once in output', () {
      final grid = generatePaletteGrid(
        cols: 10,
        rows: 10,
        colorCount: 5,
        lockedSlots: List.filled(5, false),
      );
      final seen = <int>{};
      for (int c = 0; c < 10; c++) {
        for (int r = 0; r < 10; r++) {
          seen.add(grid[c][r]);
        }
      }
      for (int i = 0; i < 5; i++) {
        expect(seen, contains(i));
      }
    });

    test('small grid 2x2 with 2 colors produces valid assignment', () {
      final grid = generatePaletteGrid(
        cols: 2,
        rows: 2,
        colorCount: 2,
        lockedSlots: List.filled(2, false),
      );
      expect(grid.length, equals(2));
      for (final col in grid) {
        expect(col.length, equals(2));
        for (final cell in col) {
          expect(cell, inInclusiveRange(0, 1));
        }
      }
    });
  });
}
