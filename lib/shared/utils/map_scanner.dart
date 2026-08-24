import 'package:centrode/infrastructure/lifecycle/daemon_gateway.dart';
import 'package:centrode/src/rust/domain/base_models.dart';

class MapInfo {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime lastModified;
  final DateTime lastAccessed;

  const MapInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.lastModified,
    required this.lastAccessed,
  });

  factory MapInfo.fromDescriptor(MapDescriptor descriptor) {
    return MapInfo(
      id: descriptor.id,
      name: descriptor.name,
      path: descriptor.storagePath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        descriptor.createdAtMs.toInt(),
      ),
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        descriptor.modifiedAtMs.toInt(),
      ),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(
        descriptor.accessedAtMs.toInt(),
      ),
    );
  }
}

class MapScanner {
  static Future<List<MapInfo>> scanMaps() async {
    if (!DaemonGateway.instance.isInitialized) {
      return [];
    }
    final descriptors = await DaemonGateway.instance.listMaps();
    return descriptors.map(MapInfo.fromDescriptor).toList();
  }

  static Future<List<MapInfo>> getRecentMaps({int limit = 50}) async {
    if (!DaemonGateway.instance.isInitialized) {
      return [];
    }
    final descriptors = await DaemonGateway.instance.getRecentMaps(limit: limit);
    return descriptors.map(MapInfo.fromDescriptor).toList();
  }

  static Future<List<MapInfo>> getProjectMaps() async {
    return scanMaps();
  }
}
