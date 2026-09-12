import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/ui/workspace_hub_screen.dart';
import 'package:centrode/shared/elements/centrode_window_title_bar.dart';
import 'package:centrode/features/workspace/ui/widgets/left_panel/left_panel.dart';
import 'package:centrode/features/workspace/ui/widgets/main_content/main_content_area.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';

void main() {
  setUp(() {
    MapManager.instance.closeAll();
  });

  tearDown(() {
    MapManager.instance.closeAll();
  });

  testWidgets('Investigate title bar overlap in WorkspaceHubScreen', (tester) async {
    debugPrint('[TEST-START] Rendering WorkspaceHubScreen at desktop resolution 1280x800');
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: WorkspaceHubScreen(),
      ),
    );
    await tester.pump();

    final titleBarFinder = find.byType(CentrodeWindowTitleBar);
    final leftPanelFinder = find.byType(LeftPanel);
    final returnToMapFinder = find.text('Return to Map');
    final mainContentFinder = find.byType(MainContentArea);

    debugPrint('[TEST] Checking existence of components...');
    debugPrint('[TEST] TitleBar found: ${titleBarFinder.evaluate().length}');
    debugPrint('[TEST] LeftPanel found: ${leftPanelFinder.evaluate().length}');
    debugPrint('[TEST] ReturnToMap found: ${returnToMapFinder.evaluate().length}');
    debugPrint('[TEST] MainContentArea found: ${mainContentFinder.evaluate().length}');

    if (titleBarFinder.evaluate().isNotEmpty) {
      final titleBarRect = tester.getRect(titleBarFinder);
      debugPrint('[TEST-GEOMETRY] TitleBar Rect: $titleBarRect');
    }

    if (leftPanelFinder.evaluate().isNotEmpty) {
      final leftPanelRect = tester.getRect(leftPanelFinder);
      debugPrint('[TEST-GEOMETRY] LeftPanel Rect: $leftPanelRect');
    }

    if (returnToMapFinder.evaluate().isNotEmpty) {
      final returnToMapRect = tester.getRect(returnToMapFinder);
      debugPrint('[TEST-GEOMETRY] ReturnToMap Rect: $returnToMapRect');
    }

    if (mainContentFinder.evaluate().isNotEmpty) {
      final mainContentRect = tester.getRect(mainContentFinder);
      debugPrint('[TEST-GEOMETRY] MainContentArea Rect: $mainContentRect');
    }

    // Check hit test on Return to Map button
    if (returnToMapFinder.evaluate().isNotEmpty && titleBarFinder.evaluate().isNotEmpty) {
      final buttonCenter = tester.getCenter(returnToMapFinder);
      final hitTestResults = tester.hitTestOnBinding(buttonCenter);
      debugPrint('[TEST-HITTEST] Hit test at ReturnToMap center ($buttonCenter):');
      for (final entry in hitTestResults.path) {
        debugPrint('   - Target: ${entry.target.runtimeType}');
      }

      final titleBarRect = tester.getRect(titleBarFinder);
      final returnRect = tester.getRect(returnToMapFinder);
      final isOverlapping = titleBarRect.overlaps(returnRect);
      debugPrint('[TEST-OVERLAP] TitleBar overlaps ReturnToMap: $isOverlapping');
      debugPrint('[TEST-OVERLAP] TitleBar bottom (${titleBarRect.bottom}) vs ReturnToMap top (${returnRect.top})');

      expect(isOverlapping, isFalse, reason: 'TitleBar must not overlap Return to Map button');
      expect(returnRect.right, lessThanOrEqualTo(titleBarRect.left),
          reason: 'Return to Map button is within LeftPanel, left of TitleBar');
    }

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Workspace Hub'),
      ),
      findsOneWidget,
    );
  });
}
