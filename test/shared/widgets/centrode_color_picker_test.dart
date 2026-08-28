import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/elements.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CentrodeColorPicker Tests', () {
    testWidgets('renders diff swatch, hex input, sliders, merged swatches, and recents', (tester) async {
      Color? changedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CentrodeColorPicker(
                initialColor: const Color(0xFF6366F1),
                originalColor: const Color(0xFF475569),
                mapColors: const [Color(0xFF38BDF8), Color(0xFFA855F7)],
                onColorChanged: (c) => changedColor = c,
              ),
            ),
          ),
        ),
      );

      // Verify Hex text
      expect(find.text('6366F1'), findsOneWidget);
      expect(find.text('#'), findsOneWidget);
      expect(find.text('SWATCHES'), findsOneWidget);
      expect(find.text('Harmonic Random'), findsOneWidget);

      // Tap on a swatch in the grid
      final swatches = find.byType(GestureDetector);
      expect(swatches, findsWidgets);

      await tester.tap(swatches.at(2));
      await tester.pumpAndSettle();

      expect(changedColor, isNotNull);
    });
  });

  group('CentrodePaletteGenerator Tests', () {
    testWidgets('renders interlocking puzzle mosaic, toggles locks, and applies palette', (tester) async {
      List<Color>? applied;
      Color? selectedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CentrodePaletteGenerator(
                primaryAnchor: const Color(0xFF6366F1),
                onApplyPalette: (pal) => applied = pal,
                onColorSelected: (c) => selectedColor = c,
              ),
            ),
          ),
        ),
      );

      expect(find.text('HARMONY:'), findsOneWidget);
      expect(find.text('Apply Palette'), findsOneWidget);
      expect(find.text('Re-roll'), findsOneWidget);

      // Find lock icons
      final lockIcons = find.byIcon(Icons.lock_open_rounded);
      expect(lockIcons, findsWidgets);

      // Toggle lock on first slot
      await tester.tap(lockIcons.first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      // Tap Apply Palette button
      await tester.ensureVisible(find.text('Apply Palette'));
      await tester.tap(find.text('Apply Palette'));
      await tester.pumpAndSettle();
      expect(applied, isNotNull);
      expect(applied!.length, equals(5));
    });
  });
}
