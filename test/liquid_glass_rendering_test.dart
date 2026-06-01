import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/workspace/ui/liquid_glass_test_screen.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

void main() {
  testWidgets('LiquidGlassDemo renders and registers shapes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassDemo(),
      ),
    );

    // Let it settle to trigger any async loading
    await tester.pumpAndSettle();

    expect(find.byType(GlassPanel), findsNWidgets(4));
    expect(find.byType(GlassGroup), findsOneWidget);
  });
}
