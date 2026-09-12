import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/models/left_panel_type.dart';
import 'package:centrode/features/graph/models/graph_relation.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/left_repository_drawer.dart';
import 'package:centrode/features/graph/ui/widgets/relation_manager/global_relations_manager_panel.dart';
import 'package:centrode/features/graph/ui/widgets/relation_manager/relations_list_view.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGraphDataQueryController extends Mock implements GraphDataQueryController {}

void main() {
  group('LeftRepositoryDrawer - Relations Integration', () {
    testWidgets('renders all three buttons and toggles relations panel', (tester) async {
      LeftPanelType currentPanel = LeftPanelType.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LeftRepositoryDrawer(
                  activePanel: currentPanel,
                  onPanelChanged: (panel) {
                    setState(() {
                      currentPanel = panel;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify all three buttons are rendered with their default icons
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.byIcon(Icons.hub_outlined), findsOneWidget);

      // Tap on the relations button to open it
      await tester.tap(find.byIcon(Icons.hub_outlined));
      await tester.pumpAndSettle();

      expect(currentPanel, LeftPanelType.relations);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Tap again to toggle closed
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(currentPanel, LeftPanelType.none);
      expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    });
  });

  group('GlobalRelationsManagerPanel & RelationsListView', () {
    late MockGraphDataQueryController mockQuery;
    late StreamController<GraphEntityUpdate> updateController;

    setUp(() {
      mockQuery = MockGraphDataQueryController();
      updateController = StreamController<GraphEntityUpdate>.broadcast();
      when(() => mockQuery.onEntityUpdate).thenAnswer((_) => updateController.stream);
    });

    tearDown(() {
      updateController.close();
    });

    testWidgets('shows empty state when no relations exist', (tester) async {
      when(() => mockQuery.relations).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<GraphDataQueryController>.value(
              value: mockQuery,
              child: const SizedBox(
                width: 320,
                height: 500,
                child: GlobalRelationsManagerPanel(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('LABELS'), findsOneWidget);
      expect(find.text('No labels in graph'), findsOneWidget);
    });

    testWidgets('renders relation verbs with usage counts and filters via search', (tester) async {
      final relations = [
        InfoUiRelation(
          fromNodeId: RawUuid.v4(),
          fromNodeTable: 'node',
          toNodeId: RawUuid.v4(),
          toNodeTable: 'node',
          verb: 'causes',
        ),
        InfoUiRelation(
          fromNodeId: RawUuid.v4(),
          fromNodeTable: 'node',
          toNodeId: RawUuid.v4(),
          toNodeTable: 'node',
          verb: 'causes',
        ),
        InfoUiRelation(
          fromNodeId: RawUuid.v4(),
          fromNodeTable: 'node',
          toNodeId: RawUuid.v4(),
          toNodeTable: 'node',
          verb: 'depends on',
        ),
      ];

      when(() => mockQuery.relations).thenReturn(relations);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<GraphDataQueryController>.value(
              value: mockQuery,
              child: const SizedBox(
                width: 320,
                height: 500,
                child: GlobalRelationsManagerPanel(),
              ),
            ),
          ),
        ),
      );

      // Verify verbs and counts
      expect(find.text('causes'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 usages of causes
      expect(find.text('depends on'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 usage of depends on

      // Search filter
      await tester.enterText(find.byType(TextField), 'cause');
      await tester.pumpAndSettle();

      expect(find.text('causes'), findsOneWidget);
      expect(find.text('depends on'), findsNothing);

      // Non-matching search query
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('No matching labels'), findsOneWidget);
    });
  });
}
