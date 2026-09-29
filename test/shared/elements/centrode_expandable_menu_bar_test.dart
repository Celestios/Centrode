import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/elements.dart';

void main() {
  testWidgets(
    'CentrodeExpandableMenuBar renders without RenderFlex overflow in collapsed state',
    (tester) async {
      final sections = [
        CentrodeMenuSection(
          title: 'File',
          items: [ContextMenuItem.action(label: 'Save', onTap: () {})],
        ),
        CentrodeMenuSection(
          title: 'Edit',
          items: [ContextMenuItem.action(label: 'Undo', onTap: () {})],
        ),
        CentrodeMenuSection(
          title: 'View',
          items: [ContextMenuItem.action(label: 'Zoom In', onTap: () {})],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 50,
                height: 40,
                child: CentrodeExpandableMenuBar(sections: sections),
              ),
            ),
          ),
        ),
      );

      // Initial collapsed render should produce no errors/overflows
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Simulate mouse hover over the menu bar
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byIcon(Icons.menu_rounded)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      // Hover exit
      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    },
  );
}
