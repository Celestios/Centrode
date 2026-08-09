import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/right_property_panel.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}
class MockGraphDataCommand extends Mock implements GraphDataCommand {}

void main() {
  testWidgets('RightPropertyPanel renders without overflow in collapsed, expanded, and selected states', (tester) async {
    final mockQuery = MockGraphDataQuery();
    final mockCommand = MockGraphDataCommand();

    when(() => mockQuery.nodeLookup).thenReturn({});
    when(() => mockQuery.relationLookup).thenReturn({});
    when(() => mockQuery.relations).thenReturn([]);
    when(() => mockQuery.onEntityUpdate).thenAnswer((_) => const Stream.empty());

    final renderState = NodeRenderState(mockQuery, mockCommand);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NodeRenderState>.value(
            value: renderState,
            child: const Align(
              alignment: Alignment.centerRight,
              child: RightPropertyPanel(),
            ),
          ),
        ),
      ),
    );

    // 1. Collapsed state without selection
    expect(tester.takeException(), isNull);
    expect(find.byType(RightPropertyPanel), findsOneWidget);

    // 2. Expand panel
    await tester.tap(find.byType(RightPropertyPanel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3. Collapse panel and trigger selection badge
    await tester.tap(find.byType(RightPropertyPanel));
    await tester.pumpAndSettle();
    renderState.selectedEntities.add(RawUuid.fromString('node-1'));
    renderState.notifyListeners();
    await tester.pumpAndSettle();

    // Verify handle with selection count badge renders cleanly without overflow
    expect(tester.takeException(), isNull);
  });
}
