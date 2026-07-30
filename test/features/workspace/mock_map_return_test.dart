import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/presentation/map_manager.dart';
import 'package:mycelium/features/workspace/ui/widgets/left_panel/quick_actions_section.dart';

void main() {
  tearDown(() {
    MapManager.instance.closeAll();
  });

  group('Return to Map Button Tests', () {
    testWidgets('QuickActionsSection renders Return to Map button instead of ACTIONS text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsSection(),
          ),
        ),
      );

      expect(find.text('ACTIONS'), findsNothing);
      expect(find.text('Return to Map'), findsOneWidget);
    });

    testWidgets('Return to Map button state changes dynamically based on hasOpenMaps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsSection(),
          ),
        ),
      );

      expect(MapManager.instance.hasOpenMaps, isFalse);

      // Open a map session
      MapManager.instance.openMap('maps/test.db', 'Test Map');
      await tester.pump();

      expect(MapManager.instance.hasOpenMaps, isTrue);
      expect(find.text('Return to Map'), findsOneWidget);

      // Close all maps
      MapManager.instance.closeAll();
      await tester.pump();

      expect(MapManager.instance.hasOpenMaps, isFalse);
    });
  });
}
