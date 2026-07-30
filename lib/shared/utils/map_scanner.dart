import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_paths.dart';
import 'recent_maps_store.dart';

class MapInfo {
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime lastModified;
  final DateTime lastAccessed;

  const MapInfo({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.lastModified,
    required this.lastAccessed,
  });
}

class MapScanner {
  static Future<List<MapInfo>> scanMaps() async {
    final mapsDir = await AppPaths.mapsDirectory;
    final directory = Directory(mapsDir);
    final accessTimes = await RecentMapsStore.getAll();

    if (!directory.existsSync()) {
      return [];
    }

    final maps = <MapInfo>[];
    final entities = await directory.list().toList();

    for (final entity in entities) {
      if (entity.path.endsWith('.db')) {
        final stat = await entity.stat();
        final name = p.basenameWithoutExtension(entity.path);
        maps.add(MapInfo(
          name: name,
          path: entity.path,
          createdAt: stat.changed,
          lastModified: stat.modified,
          lastAccessed: accessTimes[entity.path] ?? stat.modified,
        ));
      }
    }

    return maps;
  }

  static Future<List<MapInfo>> getRecentMaps() async {
    final maps = await scanMaps();
    maps.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
    return maps;
  }

  static Future<List<MapInfo>> getProjectMaps() async {
    final maps = await scanMaps();
    maps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return maps;
  }
}
