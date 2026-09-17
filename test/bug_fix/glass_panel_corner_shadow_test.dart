import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/presentation/widgets/left_repository_panel.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/features/workspace/ui/widgets/left_panel/left_panel.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/right_property_panel.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';

class _MockGraphDataQuery extends Mock implements GraphDataQuery {}
class _MockGraphDataCommand extends Mock implements GraphDataCommand {}

void main() {
  testWidgets('Diagnose GlassPanel and LeftRepositoryPanel shadow rendering and clipping',
      (tester) async {
    debugPrint('[TEST] Starting GlassPanel shadow diagnosis');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: LeftRepositoryPanel(
              title: 'GLOBAL TAGS',
              child: Container(
                color: Colors.transparent,
                height: 200,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify GlassPanel decoration is ShapeDecoration with matching ContinuousRectangleBorder
    final glassPanelFinder = find.byType(GlassPanel);
    expect(glassPanelFinder, findsOneWidget);

    final leftRepoPanel = tester.widget<LeftRepositoryPanel>(find.byType(LeftRepositoryPanel));
    expect(leftRepoPanel, isNotNull);

    final glassPanelWidget = tester.widget<GlassPanel>(glassPanelFinder);
    expect(glassPanelWidget.borderRadius, equals(UiRadius.panel));

    final containerFinder = find.descendant(
      of: glassPanelFinder,
      matching: find.byType(Container),
    );

    bool foundShapeDecoration = false;
    for (final element in containerFinder.evaluate()) {
      final container = element.widget as Container;
      if (container.decoration is ShapeDecoration) {
        final shapeDec = container.decoration as ShapeDecoration;
        if (shapeDec.shadows != null && shapeDec.shadows!.isNotEmpty) {
          foundShapeDecoration = true;
          debugPrint('[TEST] Found Outer ShapeDecoration: shape=${shapeDec.shape}, shadowsCount=${shapeDec.shadows?.length}');
          expect(shapeDec.shape, isA<ContinuousRectangleBorder>());

          // Verify intermediate shadow layers do not retract corners (spreadRadius >= 0.0 for contact and step layers)
          for (int i = 0; i < 4; i++) {
            final s = shapeDec.shadows![i];
            expect(s.spreadRadius, greaterThanOrEqualTo(0.0),
                reason: 'Shadow layer #$i should have non-negative spread radius to prevent corner retraction');
          }
        }
      }
    }
    expect(foundShapeDecoration, isTrue, reason: 'GlassPanel must use ShapeDecoration so shadows follow the exact squircle path');

    // 2. Verify _GlassSpecularBorderPainter paints without exceptions
    final customPaintFinder = find.descendant(
      of: glassPanelFinder,
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsWidgets);
  });

  testWidgets('Workspace Hub LeftPanel renders with custom asymmetric squircle shadow and no outer ClipRRect',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LeftPanel(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify LeftPanel is not wrapped in a ClipRRect (which would clip corner shadows)
    expect(
      find.ancestor(of: find.byType(LeftPanel), matching: find.byType(ClipRRect)),
      findsNothing,
      reason: 'LeftPanel should not have an outer ClipRRect cutting off edge shadows',
    );

    // Verify LeftPanel uses GlassPanel with customBorderRadius for top-right and bottom-right
    final glassPanelFinder = find.descendant(
      of: find.byType(LeftPanel),
      matching: find.byType(GlassPanel),
    );
    expect(glassPanelFinder, findsWidgets);

    final glassPanel = tester.widgetList<GlassPanel>(glassPanelFinder).first;
    expect(
      glassPanel.customBorderRadius,
      equals(const BorderRadius.only(
        topRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
        bottomRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
      )),
    );

    // Verify ShapeDecoration uses ContinuousRectangleBorder with matching asymmetric borderRadius
    final containerFinder = find.descendant(
      of: glassPanelFinder.first,
      matching: find.byType(Container),
    );
    bool foundMatchingShape = false;
    for (final element in containerFinder.evaluate()) {
      final container = element.widget as Container;
      if (container.decoration is ShapeDecoration) {
        final shapeDec = container.decoration as ShapeDecoration;
        if (shapeDec.shadows != null &&
            shapeDec.shadows!.isNotEmpty &&
            shapeDec.shape is ContinuousRectangleBorder) {
          final border = shapeDec.shape as ContinuousRectangleBorder;
          if (border.borderRadius ==
              const BorderRadius.only(
                topRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
                bottomRight: Radius.circular(WorkspaceTokens.leftPanelRadius),
              )) {
            foundMatchingShape = true;
            break;
          }
        }
      }
    }
    expect(foundMatchingShape, isTrue,
        reason: 'ShapeDecoration must use asymmetric ContinuousRectangleBorder matching customBorderRadius');
  });

  testWidgets('Inspector RightPropertyPanel renders single-surface GlassPanel without redundant outer container border',
      (tester) async {
    final mockQuery = _MockGraphDataQuery();
    final mockCommand = _MockGraphDataCommand();

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
    await tester.pumpAndSettle();

    // Expand panel by tapping handle
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify GlassPanel instances in RightPropertyPanel
    final glassPanels = find.descendant(
      of: find.byType(RightPropertyPanel),
      matching: find.byType(GlassPanel),
    );
    expect(glassPanels, findsNWidgets(2)); // 1 for handle, 1 for content panel

    // Verify content GlassPanel has borderRadius: UiRadius.panel (16.0)
    final contentGlassPanel = tester.widgetList<GlassPanel>(glassPanels).last;
    expect(contentGlassPanel.borderRadius, equals(UiRadius.panel));
  });
}
