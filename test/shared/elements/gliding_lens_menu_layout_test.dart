import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/elements.dart';

void main() {
  testWidgets(
    'gliding-lens menu sizes itself to its content and stays interactive',
    (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CentrodeContextMenu.showAt(
                    context: context,
                    targetRect: const Rect.fromLTWH(40, 40, 90, 28),
                    positioningMode: MenuPositioningMode.below,
                    useGlidingLens: true,
                    items: [
                      ContextMenuItem.action(
                        label: 'Force Sync Save',
                        shortcut: 'Ctrl+S',
                        onTap: () => saved = true,
                      ),
                      const ContextMenuItem.divider(),
                      ContextMenuItem.action(
                        label: 'Toggle Left Sidebar',
                        onTap: () {},
                      ),
                    ],
                  );
                },
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The overlay hands this card loose, unbounded height, which used to
      // blow up LiquidGlassView's StackFit.expand layout.
      expect(tester.takeException(), isNull);

      // One hit-testable copy of the label: the invisible sizer column that
      // also carries the pointer targets. The painted copy behind the glass
      // is IgnorePointer'd.
      expect(find.text('Force Sync Save').hitTestable(), findsOneWidget);

      // The menu hugs its content instead of stretching to the screen.
      final menuSize = tester.getSize(find.byType(ScaleTransition).first);
      expect(menuSize.height, greaterThan(40));
      expect(menuSize.height, lessThan(200));

      await tester.tap(find.text('Force Sync Save').hitTestable());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(saved, isTrue);
      expect(find.text('Force Sync Save'), findsNothing);
    },
  );
}
