import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MapInfo {
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime lastModified;

  const MapInfo({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.lastModified,
  });
}

class MapScanner {
  static Future<String> get _mapsDirectory async {
    if (!kReleaseMode) {
      return p.join(Directory.current.path, 'maps');
    } else {
      final appDocsDir = await getApplicationDocumentsDirectory();
      return p.join(appDocsDir.path, 'maps');
    }
  }

  static Future<List<MapInfo>> scanMaps() async {
    final mapsDir = await _mapsDirectory;
    final directory = Directory(mapsDir);

    if (!directory.existsSync()) {
      return [];
    }

    final maps = <MapInfo>[];
    final files = directory.listSync().whereType<File>();

    for (final file in files) {
      if (file.path.endsWith('.db')) {
        final stat = file.statSync();
        final name = p.basenameWithoutExtension(file.path);
        maps.add(MapInfo(
          name: name,
          path: file.path,
          createdAt: stat.changed,
          lastModified: stat.modified,
        ));
      }
    }

    return maps;
  }

  static Future<List<MapInfo>> getRecentMaps() async {
    final maps = await scanMaps();
    maps.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return maps;
  }

  static Future<List<MapInfo>> getProjectMaps() async {
    final maps = await scanMaps();
    maps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return maps;
  }
}
