import 'package:centrode/src/rust/domain/base_models.dart';

abstract class MapStorageGateway {
  bool get isInitialized;
  Future<List<MapDescriptor>> listMaps();
  Future<List<MapDescriptor>> getRecentMaps({int limit = 50});
  Future<MapDescriptor> createMap(String name);
  Future<void> deleteMap(String mapId);
  Future<MapDescriptor> renameMap(String mapId, String newName);
  Future<MapDescriptor> duplicateMap(String mapId, String newName);
  Future<void> touchMap(String mapId);
  Future<MapDescriptor> getMap(String mapId);
}
