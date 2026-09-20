import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/ui/workspace_hub_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/elements/hover_scale_button.dart';
import 'package:centrode/shared/theme/ui_strings.dart';

void main() {
  group('Workspace Hub Return to Map Button', () {
    setUp(() {
      MapManager.instance.closeAll();
    });

    tearDown(() {
      MapManager.instance.closeAll();
    });

    testWidgets(
      'button is disabled initially and enables reactively when map is opened',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: WorkspaceHubScreen()));
        await tester.pumpAndSettle();

        final returnToMapFinder = find.widgetWithText(
          HoverScaleButton,
          UiStrings.commands.returnToMap,
        );
        expect(returnToMapFinder, findsOneWidget);

        HoverScaleButton button = tester.widget<HoverScaleButton>(
          returnToMapFinder,
        );
        expect(button.isEnabled, isFalse);
        expect(button.onTap, isNull);

        // Simulate a map opening via MapManager
        final fakeTabs = WorkspaceTabsController(
          initialPath: 'maps/test.db',
          initialName: 'Test Map',
        );
        MapManager.instance.tabsControllerForTesting = fakeTabs;
        MapManager.instance.notifyListeners();

        await tester.pump();

        button = tester.widget<HoverScaleButton>(returnToMapFinder);
        expect(button.isEnabled, isTrue);
        expect(button.onTap, isNotNull);

        // Simulate closing all tabs
        MapManager.instance.closeAll();
        await tester.pump();

        button = tester.widget<HoverScaleButton>(returnToMapFinder);
        expect(button.isEnabled, isFalse);
        expect(button.onTap, isNull);
      },
    );
  });
}
