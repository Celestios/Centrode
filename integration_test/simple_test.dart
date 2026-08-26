import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Renders boot splash while initializing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CentrodeApp());
    await tester.pump();
    expect(find.text('CENTRODE'), findsOneWidget);
  });
}
