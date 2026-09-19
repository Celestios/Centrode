import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';

void main() {
  group('WorkspaceHubController', () {
    late WorkspaceHubController controller;

    setUp(() {
      MapManager.instance.closeAll();
      controller = WorkspaceHubController();
    });

    tearDown(() {
      controller.dispose();
      MapManager.instance.closeAll();
    });

    test('hasOpenMaps returns false when no maps are open', () {
      expect(controller.hasOpenMaps, isFalse);
    });

    test('createNewMap triggers notification', () async {
      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      await controller.createNewMap(name: 'Test Map');

      expect(notificationCount, 1);
    });

    test('deleteMaps triggers notification', () async {
      await controller.createNewMap(name: 'Test Map');

      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      final maps = await controller.fetchRecentMaps();
      if (maps.isNotEmpty) {
        await controller.deleteMaps([maps.first]);
        expect(notificationCount, 1);
      }
    });

    test('fetchRecentMaps returns a list', () async {
      final maps = await controller.fetchRecentMaps();
      expect(maps, isA<List>());
    });

    test('fetchProjectMaps returns a list', () async {
      final maps = await controller.fetchProjectMaps();
      expect(maps, isA<List>());
    });
  });
}
