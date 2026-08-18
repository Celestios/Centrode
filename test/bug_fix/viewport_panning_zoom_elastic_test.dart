import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/widgets/canvas_interactive_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasInteractiveViewer Panning & Zoom Tests', () {
    late TransformationController controller;

    setUp(() {
      controller = TransformationController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('allows free panning when zoomed in within content bounds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CanvasInteractiveViewer(
                transformationController: controller,
                contentBounds: const Rect.fromLTRB(-2000, -2000, 2000, 2000),
                minScale: 0.2,
                maxScale: 5.0,
                child: Container(
                  width: 4000,
                  height: 4000,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Set zoom to 2.0
      controller.value = Matrix4.identity()
        ..translateByDouble(0, 0, 0, 1)
        ..scaleByDouble(2.0, 2.0, 2.0, 1);
      await tester.pumpAndSettle();

      final initialTranslation = controller.value.getTranslation();

      // Pan with secondary mouse drag
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.down(const Offset(400, 300));
      await gesture.moveBy(const Offset(-100, -50));
      await tester.pump();

      final currentTranslation = controller.value.getTranslation();

      // Translation should have changed by -100 in X and -50 in Y without being clamped
      expect(currentTranslation.x, closeTo(initialTranslation.x - 100, 1.0));
      expect(currentTranslation.y, closeTo(initialTranslation.y - 50, 1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('elastic overscroll applies when panning past content bounds and springs back', (tester) async {
      Offset overscroll = Offset.zero;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: CanvasInteractiveViewer(
                transformationController: controller,
                contentBounds: const Rect.fromLTRB(-500, -500, 500, 500),
                minScale: 0.2,
                maxScale: 3.0,
                onElasticOverscroll: (val) {
                  overscroll = val;
                },
                child: Container(
                  width: 1000,
                  height: 1000,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
      );

      // Content at scale 1.0: bounds [-500, 500], screen size 800x600
      // maxTx = -(-500) = 500.
      // Pan far to the right to exceed maxTx
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.down(const Offset(400, 300));
      await gesture.moveBy(const Offset(1000, 0)); // Large drag
      await tester.pump();

      // Overscroll should be non-zero and positive in X
      expect(overscroll.dx, greaterThan(0));

      // Release pointer - spring back should occur
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // After spring settles, overscroll must be zero
      expect(overscroll, equals(Offset.zero));
    });
  });
}
