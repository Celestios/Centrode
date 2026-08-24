import 'package:centrode/src/rust/bridge/api.dart';
import 'package:centrode/src/rust/domain/base_models.dart';

class DaemonGateway {
  static final DaemonGateway instance = DaemonGateway._();
  DaemonGateway._();

  DaemonHandle? _handle;

  DaemonHandle get handle {
    if (_handle == null) {
      throw StateError('DaemonHandle not initialized');
    }
    return _handle!;
  }

  bool get isInitialized => _handle != null;

  Future<void> init(String storagePath) async {
    _handle = await DaemonHandle.newInstance(storagePath: storagePath);
  }

  Future<List<MapDescriptor>> listMaps() => handle.listMaps();

  Future<List<MapDescriptor>> getRecentMaps({int limit = 50}) =>
      handle.getRecentMaps(limit: BigInt.from(limit));

  Future<MapDescriptor> createMap(String name) => handle.createMap(name: name);

  Future<void> deleteMap(String mapId) => handle.deleteMap(mapId: mapId);

  Future<MapDescriptor> renameMap(String mapId, String newName) =>
      handle.renameMap(mapId: mapId, newName: newName);

  Future<MapDescriptor> duplicateMap(String mapId, String newName) =>
      handle.duplicateMap(mapId: mapId, newName: newName);

  Future<void> touchMap(String mapId) => handle.touchMap(mapId: mapId);

  Future<MapDescriptor> getMap(String mapId) => handle.getMap(mapId: mapId);

  Future<String?> getSetting(String key) => handle.getSetting(key: key);

  Future<void> setSetting(String key, String value) =>
      handle.setSetting(key: key, value: value);

  Future<void> deleteSetting(String key) => handle.deleteSetting(key: key);

  Future<void> shutdown() async {
    if (_handle != null) {
      await _handle!.shutdown();
      _handle = null;
    }
  }
}
