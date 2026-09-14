import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/src/rust/domain/base_models.dart';
import 'package:path/path.dart' as p;

void main() {
  test('AppPaths resolves dev root and mapsDirectory correctly', () async {
    final mapsDir = await AppPaths.mapsDirectory;
    expect(mapsDir, endsWith('maps'));
    expect(p.basename(mapsDir), equals('maps'));
  });

  test('MapScanner returns empty list when daemon is uninitialized', () async {
    final maps = await MapScanner.scanMaps();
    final recent = await MapScanner.getRecentMaps();
    final projects = await MapScanner.getProjectMaps();

    expect(maps, isEmpty);
    expect(recent, isEmpty);
    expect(projects, isEmpty);
  });

  test('MapInfo.fromDescriptor parses test daemon descriptor fixtures correctly', () {
    const descriptor = MapDescriptor(
      id: 'map-optic-earth',
      name: 'optic-earth',
      storagePath: '/data/maps/optic-earth.db',
      createdAtMs: 1600000000000,
      modifiedAtMs: 1600000001000,
      accessedAtMs: 1600000002000,
    );

    final mapInfo = MapInfo.fromDescriptor(descriptor);

    expect(mapInfo.id, equals('map-optic-earth'));
    expect(mapInfo.name, equals('optic-earth'));
    expect(mapInfo.path, endsWith('optic-earth.db'));
    expect(
      mapInfo.createdAt,
      equals(DateTime.fromMillisecondsSinceEpoch(1600000000000)),
    );
    expect(
      mapInfo.lastModified,
      equals(DateTime.fromMillisecondsSinceEpoch(1600000001000)),
    );
    expect(
      mapInfo.lastAccessed,
      equals(DateTime.fromMillisecondsSinceEpoch(1600000002000)),
    );
  });

  test('MapInfo correctly maps a batch of multiple map fixtures', () {
    final fixtures = [
      const MapDescriptor(
        id: 'map-1',
        name: 'optic-earth',
        storagePath: '/workspace/maps/optic-earth.db',
        createdAtMs: 1700000000000,
        modifiedAtMs: 1700000010000,
        accessedAtMs: 1700000020000,
      ),
      const MapDescriptor(
        id: 'map-2',
        name: 'knowledge-base',
        storagePath: '/workspace/maps/knowledge-base.db',
        createdAtMs: 1700000030000,
        modifiedAtMs: 1700000040000,
        accessedAtMs: 1700000050000,
      ),
    ];

    final parsedMaps = fixtures.map(MapInfo.fromDescriptor).toList();

    expect(parsedMaps, hasLength(2));
    expect(parsedMaps[0].name, equals('optic-earth'));
    expect(parsedMaps[0].path, endsWith('optic-earth.db'));
    expect(parsedMaps[1].name, equals('knowledge-base'));
    expect(parsedMaps[1].path, endsWith('knowledge-base.db'));
  });
}
