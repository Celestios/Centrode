import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/workspace/ui/liquid_glass_test_screen.dart';
import 'package:mycelium/shared/ui/liquid_glass/index.dart';
import 'package:mycelium/shared/ui/liquid_glass/liquid_glass_menu.dart';

void main() {
  testWidgets('LiquidGlassDemo renders and registers shapes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassDemo(),
      ),
    );

    // Let it settle to trigger any async loading
    await tester.pumpAndSettle();

    expect(find.byType(OCLiquidGlass), findsNWidgets(4));

    final groupFinder = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_LiquidGlassGroupRenderObject');
    expect(groupFinder, findsOneWidget);

    final Element element = tester.element(groupFinder);
    final rb = element.renderObject;
    print('RenderObject: $rb (runtimeType: ${rb.runtimeType})');

    if (rb != null) {
      final dynamic group = rb;
      final registered = group.registeredShapes;
      print('Group size: ${group.size}');
      print('Registered shapes length: ${registered.length}');
      for (final shape in registered) {
        final globalRect = MatrixUtils.transformRect(
          shape.getTransformTo(null),
          Offset.zero & shape.size,
        );
        final localRect = MatrixUtils.transformRect(
          shape.getTransformTo(rb),
          Offset.zero & shape.size,
        );
        print('Shape attached: ${shape.attached}, size: ${shape.size}');
        print('   - Global rect: $globalRect');
        print('   - Local rect: $localRect');
      }
    }
  });
}
