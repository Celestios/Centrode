import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/ui/liquid_glass_test_screen.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

void main() {
  testWidgets('LiquidGlassDemo renders and registers shapes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LiquidGlassDemo()));

    // Let it pump to trigger initial layout
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GlassPanel), findsNWidgets(4));
    expect(find.byType(GlassGroup), findsOneWidget);
  });
}
