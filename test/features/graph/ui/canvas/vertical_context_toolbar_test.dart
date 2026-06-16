import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/ui/widgets/overlays/vertical_context_toolbar.dart';

void main() {
  testWidgets(
    'VerticalContextToolbar group buttons open submenus on mouse hover',
    (WidgetTester tester) async {
      // Build the toolbar in a sized container
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 600,
                height: 600,
                child: VerticalContextToolbar(
                  onDelete: () {},
                  isMulti: false,
                  isRelationOnly: false,
                  canSaveTemplate: true,
                  singleNodeId: 'node-1',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify trigger button is displayed
      final triggerFinder = find.byIcon(Icons.category_rounded);
      expect(triggerFinder, findsOneWidget);

      // Verify submenu button (e.g. Rectangle Shape) is NOT displayed initially
      expect(find.byIcon(Icons.crop_square_rounded), findsNothing);

      // Create mouse pointer and move to the trigger button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      final triggerCenter = tester.getCenter(triggerFinder);
      await gesture.moveTo(triggerCenter);
      await tester.pumpAndSettle();

      // Verify submenu button (e.g. Rectangle Shape) IS displayed now
      expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);

      // Move pointer slightly left onto the Rectangle Shape button and verify it's still open
      final rectFinder = find.byIcon(Icons.crop_square_rounded);
      final rectCenter = tester.getCenter(rectFinder);
      await gesture.moveTo(rectCenter);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);

      // Move pointer away
      await gesture.moveTo(const Offset(0, 0));
      await tester.pumpAndSettle();

      // Verify submenu is closed again
      expect(find.byIcon(Icons.format_bold_rounded), findsNothing);
    },
  );

  testWidgets(
    'VerticalContextToolbar under loose constraints does not shift trigger button on hover',
    (WidgetTester tester) async {
      // Build the toolbar under loose constraints using Positioned in a Stack
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: VerticalContextToolbar(
                    onDelete: () {},
                    isMulti: false,
                    isRelationOnly: false,
                    canSaveTemplate: true,
                    singleNodeId: 'node-1',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final triggerFinder = find.byIcon(Icons.category_rounded);
      final initialCenter = tester.getCenter(triggerFinder);

      // Create mouse pointer and move to the trigger button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(initialCenter);
      await tester.pumpAndSettle();

      final hoveredCenter = tester.getCenter(triggerFinder);

      // Verify trigger button did not shift
      expect(initialCenter.dx, hoveredCenter.dx);
    },
  );

  testWidgets(
    'VerticalContextToolbar inside scaled and translated Transform opens submenu on hover',
    (WidgetTester tester) async {
      // Use a matrix with scale = 0.8 and translation (400, 200)
      final matrix = Matrix4.identity()
        ..translate(400.0, 200.0)
        ..scale(0.8);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Transform(
                    transform: matrix,
                    child: Transform.translate(
                      offset: const Offset(0, 0) - const Offset(340, 0),
                      child: VerticalContextToolbar(
                        onDelete: () {},
                        isMulti: false,
                        isRelationOnly: false,
                        canSaveTemplate: true,
                        singleNodeId: 'node-1',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final triggerFinder = find.byIcon(Icons.category_rounded);
      expect(triggerFinder, findsOneWidget);

      final triggerCenter = tester.getCenter(triggerFinder);

      // Verify submenu button is NOT displayed initially
      expect(find.byIcon(Icons.crop_square_rounded), findsNothing);

      // Hover mouse over the trigger button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(triggerCenter);
      await tester.pumpAndSettle();

      // Verify submenu button IS displayed now
      expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'VerticalContextToolbar with isRelationOnly triggers onRelationLayoutChanged callback',
    (WidgetTester tester) async {
      String? selectedLayout;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 600,
                height: 600,
                child: VerticalContextToolbar(
                  onDelete: () {},
                  isMulti: false,
                  isRelationOnly: true,
                  onRelationLayoutChanged: (layout) => selectedLayout = layout,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify relation trigger button is displayed
      final triggerFinder = find.byIcon(Icons.timeline_rounded);
      expect(triggerFinder, findsOneWidget);

      // Verify submenu button is NOT displayed initially
      expect(find.byIcon(Icons.linear_scale_rounded), findsNothing);

      // Hover mouse over the trigger button to open submenu
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(triggerFinder));
      await tester.pumpAndSettle();

      // Verify Straight Route (linear_scale_rounded) is displayed now
      final straightFinder = find.byIcon(Icons.linear_scale_rounded);
      expect(straightFinder, findsOneWidget);

      // Click Straight Route
      await tester.tap(straightFinder);
      await tester.pumpAndSettle();

      expect(selectedLayout, 'default');

      // Click Bezier Route (gesture_rounded)
      final bezierFinder = find.byIcon(Icons.gesture_rounded);
      expect(bezierFinder, findsOneWidget);
      await tester.tap(bezierFinder);
      await tester.pumpAndSettle();

      expect(selectedLayout, 'bezier');

      // Click Manhattan Route (route_rounded)
      final manhattanFinder = find.byIcon(Icons.route_rounded);
      expect(manhattanFinder, findsOneWidget);
      await tester.tap(manhattanFinder);
      await tester.pumpAndSettle();

      expect(selectedLayout, 'orthogonal');
    },
  );
}
