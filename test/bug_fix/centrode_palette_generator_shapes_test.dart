import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/centrode_palette_generator.dart';

void main() {
  testWidgets('CentrodePaletteGenerator builds, renders shapes, and supports interactions', (tester) async {
    debugPrint('[TEST] Rendering CentrodePaletteGenerator');
    List<Color>? appliedPalette;
    Color? selectedColor;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CentrodePaletteGenerator(
              primaryAnchor: const Color(0xFF6366F1),
              onApplyPalette: (palette) => appliedPalette = palette,
              onColorSelected: (color) => selectedColor = color,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CentrodePaletteGenerator), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('HARMONY:'), findsOneWidget);
    expect(find.text('Re-roll'), findsOneWidget);
    expect(find.text('Apply Palette'), findsOneWidget);

    // Test Apply Palette button callback
    await tester.tap(find.text('Apply Palette'));
    await tester.pumpAndSettle();
    expect(appliedPalette, isNotNull);
    expect(appliedPalette!.length, 5);

    // Test Re-roll button
    await tester.tap(find.text('Re-roll'));
    await tester.pumpAndSettle();

    // Test Harmony mood chip selection
    await tester.tap(find.text('Vibrant'));
    await tester.pumpAndSettle();

    // Test lock toggle icon
    final lockIcons = find.byIcon(Icons.lock_open_rounded);
    expect(lockIcons, findsWidgets);
    await tester.tap(lockIcons.first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    debugPrint('[TEST] All CentrodePaletteGenerator interactions verified successfully');
  });
}
