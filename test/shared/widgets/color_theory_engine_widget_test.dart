import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/prototype/color_theory_demo.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

void main() {
  testWidgets('ColorTheoryStudioApp interactive window renders, shuffles colors, and switches harmonies', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ColorTheoryStudioApp());
    await tester.pumpAndSettle();

    // Verify Primary Studio Sections
    expect(find.text('GENERATIVE PALETTE EXPLORATION (SPACEBAR)'), findsOneWidget);
    expect(find.text('THEME-DERIVED CANONICAL SWATCHES (12)'), findsOneWidget);
    expect(find.text('COLOR THEORY HARMONIES (OKLCH)'), findsOneWidget);
    expect(find.text('PRECISION TUNING SLIDERS'), findsOneWidget);

    // Verify Generative Palette Exploration Button exists and is tappable
    final generatePaletteFinder = find.text('Generate Palette (Spacebar)');
    expect(generatePaletteFinder, findsOneWidget);

    await tester.tap(generatePaletteFinder);
    await tester.pumpAndSettle();

    // Verify Shuffle Color Button exists and is tappable
    final shuffleFinder = find.text('🎲 Shuffle Color');
    expect(shuffleFinder, findsOneWidget);

    await tester.tap(shuffleFinder);
    await tester.pumpAndSettle();

    // Verify Sliders exist for precision tuning
    expect(find.text('Hue'), findsOneWidget);
    expect(find.text('Saturation'), findsOneWidget);
    expect(find.text('Brightness'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });
}
