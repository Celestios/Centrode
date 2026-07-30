import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/shared/utils/app_paths.dart';
import 'package:mycelium/shared/utils/map_scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  test('AppPaths resolves dev root and mapsDirectory correctly', () async {
    final mapsDir = await AppPaths.mapsDirectory;
    expect(mapsDir, endsWith('maps'));
    expect(p.basename(mapsDir), equals('maps'));
  });

  test('MapScanner scans both file and directory .db entries', () async {
    final maps = await MapScanner.scanMaps();
    final recent = await MapScanner.getRecentMaps();
    final projects = await MapScanner.getProjectMaps();

    expect(recent.length, equals(maps.length));
    expect(projects.length, equals(maps.length));

    // If optic-earth.db exists in maps directory, ensure it is found regardless of being a directory
    if (maps.any((m) => m.name == 'optic-earth')) {
      final map = maps.firstWhere((m) => m.name == 'optic-earth');
      expect(map.path, endsWith('optic-earth.db'));
    }
  });
}
