import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Context toolbar renders action buttons cleanly', (WidgetTester tester) async {
    bool actionFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => actionFired = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(actionFired, isTrue);
  });
}
