import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/features/graph/ui/canvas/layers/grid_layer.dart';

void main() {
  testWidgets('GridLayer renders cleanly at zoom scale 1.0 and scale 0.2', (tester) async {
    final viewportNotifier = ValueNotifier<ViewportStateGrid>(
      const ViewportStateGrid(
        viewportSize: Size(800, 600),
        visibleRect: Rect.fromLTWH(0, 0, 800, 600),
        scale: 1.0,
      ),
    );
    final mousePosNotifier = ValueNotifier<Offset?>(const Offset(400, 300));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridLayer(
            viewportState: viewportNotifier.value,
            mousePositionNotifier: mousePosNotifier,
          ),
        ),
      ),
    );

    expect(find.byType(GridLayer), findsOneWidget);

    // Zoom out to scale 0.2
    viewportNotifier.value = const ViewportStateGrid(
      viewportSize: Size(800, 600),
      visibleRect: Rect.fromLTWH(0, 0, 4000, 3000),
      scale: 0.2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridLayer(
            viewportState: viewportNotifier.value,
            mousePositionNotifier: mousePosNotifier,
          ),
        ),
      ),
    );

    expect(find.byType(GridLayer), findsOneWidget);
  });
}
