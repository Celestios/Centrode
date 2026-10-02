import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/ui/widgets/main_content/project_card.dart';
import 'package:centrode/shared/elements/elements.dart';

void main() {
  Widget buildTestCard({
    String name = 'Test Map',
    String lastOpened = '2h ago',
    int? seed,
    Color? previewColor,
    ContourConfig? contourConfig,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: WorkspaceTokens.cardWidth,
            height: WorkspaceTokens.cardHeight,
            child: ProjectCard(
              name: name,
              lastOpened: lastOpened,
              seed: seed,
              previewColor: previewColor,
              contourConfig: contourConfig,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  group('ProjectCard', () {
    testWidgets('renders title, last opened, and aesthetic hub icon preview', (tester) async {
      await tester.pumpWidget(buildTestCard());

      expect(find.text('Test Map'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
      expect(find.byIcon(Icons.hub_rounded), findsOneWidget);
      expect(find.byType(CentrodeContourPattern), findsOneWidget);
    });

    testWidgets('triggers onTap callback when clicked', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestCard(onTap: () => tapped = true));

      await tester.tap(find.byIcon(Icons.hub_rounded));
      expect(tapped, isTrue);
    });

    testWidgets('different seeds generate distinct aesthetic preview gradients', (tester) async {
      await tester.pumpWidget(buildTestCard(name: 'Map 1', seed: 42));
      final container1Finder = find.descendant(
        of: find.byType(ProjectCard),
        matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null),
      );
      expect(container1Finder, findsOneWidget);
      final container1 = tester.widget<Container>(container1Finder);
      final gradient1 = (container1.decoration as BoxDecoration).gradient as LinearGradient;

      await tester.pumpWidget(buildTestCard(name: 'Map 2', seed: 9999));
      final container2 = tester.widget<Container>(container1Finder);
      final gradient2 = (container2.decoration as BoxDecoration).gradient as LinearGradient;

      expect(gradient1.colors.first, isNot(equals(gradient2.colors.first)));
    });

    testWidgets('explicit previewColor overrides generated aesthetic color', (tester) async {
      const customColor = Color(0xFFE91E63);
      await tester.pumpWidget(buildTestCard(previewColor: customColor));

      final icon = tester.widget<Icon>(find.byIcon(Icons.hub_rounded));
      expect(icon.color, equals(customColor));
    });

    testWidgets('explicit contourConfig tunes pattern properties', (tester) async {
      const customConfig = ContourConfig(
        style: ContourStyle.flowingWaves,
        layerCount: 3,
        amplitude: 0.5,
        frequency: 2.0,
        showLines: false,
      );

      await tester.pumpWidget(buildTestCard(contourConfig: customConfig));
      final patternFinder = find.byType(CentrodeContourPattern);
      expect(patternFinder, findsOneWidget);
      final pattern = tester.widget<CentrodeContourPattern>(patternFinder);
      expect(pattern.config.style, equals(ContourStyle.flowingWaves));
      expect(pattern.config.layerCount, equals(3));
      expect(pattern.config.amplitude, equals(0.5));
    });
  });
}
