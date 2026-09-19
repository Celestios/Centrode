import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/left_panel_type.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/left_repository_drawer.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/tab_bar/add_tab_button.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LeftRepositoryDrawer', () {
    testWidgets('renders all 4 tabs and triggers selection', (tester) async {
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

      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
      expect(find.byIcon(Icons.draw_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.draw_rounded));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.draw);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.none);
      expect(find.byIcon(Icons.draw_rounded), findsOneWidget);
    });

    testWidgets('toggles tags panel', (tester) async {
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

      await tester.tap(find.byIcon(Icons.local_offer_outlined));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.tags);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.none);
    });

    testWidgets('toggles templates panel', (tester) async {
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

      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.templates);
    });

    testWidgets('toggles relations panel', (tester) async {
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

      await tester.tap(find.byIcon(Icons.hub_outlined));
      await tester.pumpAndSettle();
      expect(currentPanel, LeftPanelType.relations);
    });
  });

  group('AddTabButton', () {
    testWidgets('renders collapsed state with add icon', (tester) async {
      final controller = WorkspaceTabsController(
        initialPath: 'maps/test.db',
        initialName: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTabButton(tabsController: controller),
          ),
        ),
      );

      expect(find.byType(AddTabButton), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });
}
