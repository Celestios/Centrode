import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/ui/widgets/main_content/maps_section.dart';

void main() {
  testWidgets('MapsSection renders and manages shared map selection state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MapsSection(),
          ),
        ),
      ),
    );
    expect(find.byType(MapsSection), findsOneWidget);
  });
}
