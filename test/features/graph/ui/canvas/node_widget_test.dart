import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/ui/canvas/node_widget.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

import 'package:mycelium/features/graph/models/content_builder.dart';

import 'package:provider/provider.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

class MockGraphDataQuery extends Mock with ChangeNotifier implements GraphDataQuery {
  @override
  Map<String, UiNode> get nodeLookup => {};
}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme => const GraphTheme(
    id: 'test',
    name: 'test',
  );
}

void main() {
  testWidgets('NodeWidget renders InfoUiNode correctly', (WidgetTester tester) async {
    final mockQuery = MockGraphDataQuery();
    final mockTheme = MockThemeController();

    final node = InfoUiNode(
      id: 'test-node-1',
      position: const Offset(0, 0),
      size: const Size(200, 100),
      content: ContentFactory.fromText('Test Node'),
      resolvedStyle: const NodeStyle(
        bgColor: 0xFFFFFFFF,
        strokeColor: 0xFF000000,
        strokeWidth: 1,
        fontFamily: 'Roboto',
        fontSize: 14,
        shape: 'rectangle',
        width: 200,
        height: 100,
        textColor: 0xFF000000,
        borderRadius: 8.0,
        padding: 8.0,
        shadowColor: 0x00000000,
        shadowBlur: 0,
        shadowSpread: 0,
        shadowOffsetX: 0,
        shadowOffsetY: 0,
        strategyType: 'info',
      ),
    );

    final viewState = NodeViewState(node);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ListenableProvider<GraphDataQuery>.value(value: mockQuery),
            ChangeNotifierProvider<ThemeController>.value(value: mockTheme),
          ],
          child: Scaffold(
            body: Stack(
              children: [
                NodeWidget(
                  node: node,
                  viewState: viewState,
                  isSelected: false,
                  isEditing: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify it renders the text
    expect(find.text('Test Node'), findsOneWidget);
  });
}
