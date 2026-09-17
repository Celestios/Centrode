import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/widgets/context_menu_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CentrodeContextMenu Tests', () {
    testWidgets('renders solid non-transparent background with items', (tester) async {
      bool copyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CentrodeContextMenu.show(
                    context: context,
                    position: const Offset(100, 100),
                    items: [
                      ContextMenuItem.action(
                        label: 'Copy',
                        shortcut: 'Ctrl+C',
                        leadingIcon: Icons.copy,
                        onTap: () => copyTapped = true,
                      ),
                      const ContextMenuItem.divider(),
                      ContextMenuItem.destructive(
                        label: 'Delete',
                        shortcut: 'Del',
                        leadingIcon: Icons.delete,
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
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Ctrl+C'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Del'), findsOneWidget);

      final copyFinder = find.text('Copy');
      expect(copyFinder, findsOneWidget);

      await tester.tap(copyFinder);
      await tester.pumpAndSettle();

      expect(copyTapped, isTrue);
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('positions menu outside target node boundary and avoids obstacles', (tester) async {
      const targetRect = Rect.fromLTWH(100, 100, 200, 150);
      const avoidRect = Rect.fromLTWH(305, 100, 150, 80);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CentrodeContextMenu.show(
                    context: context,
                    position: const Offset(150, 120),
                    targetRect: targetRect,
                    avoidRects: const [avoidRect],
                    items: [
                      ContextMenuItem.action(
                        label: 'ActionItem',
                        onTap: () {},
                      ),
                    ],
                  );
                },
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      final itemFinder = find.text('ActionItem');
      expect(itemFinder, findsOneWidget);

      final itemTopLeft = tester.getTopLeft(itemFinder);
      final itemBottomRight = tester.getBottomRight(itemFinder);
      final itemRect = Rect.fromPoints(itemTopLeft, itemBottomRight);

      expect(itemRect.overlaps(targetRect), isFalse);
      expect(itemRect.overlaps(avoidRect), isFalse);
    });
  });
}
