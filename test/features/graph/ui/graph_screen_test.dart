import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/ui/graph_screen.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';

import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockGraphDataController extends Mock implements GraphDataController {
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  void Function(String) get onError => (String err) {};
}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme =>
      const GraphTheme(id: 'test', name: 'test');
}

void main() {
  testWidgets('GraphScreen renders without crashing', (
    WidgetTester tester,
  ) async {
    final mockController = MockGraphDataController();
    final mockTheme = MockThemeController();

    // Since GraphScreen requires MultiProvider with these providers...
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<GraphDataController>.value(
              value: mockController,
            ),
            ChangeNotifierProvider<ThemeController>.value(value: mockTheme),
          ],
          child: const GraphScreen(storagePath: ''),
        ),
      ),
    );

    // It should render some part of the GraphScreen. GraphCanvas might require
    // more thorough mocking (e.g. InteractionFacade etc.), but this checks basic init.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
