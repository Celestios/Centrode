import 'package:flutter/foundation.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/utils/name_generator.dart';
import 'package:centrode/shared/utils/map_scanner.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/features/graph/presentation/map_storage_gateway.dart';
import 'package:centrode/src/rust/domain/base_models.dart' show MapDescriptor;

class WorkspaceHubController extends ChangeNotifier {
  final Logger _log = Logger('WorkspaceHubController');
  final MapManager _mapManager;
  final MapStorageGateway? _storageGateway;

  WorkspaceHubController({
    MapManager? mapManager,
    MapStorageGateway? storageGateway,
  })  : _mapManager = mapManager ?? MapManager.instance,
        _storageGateway = storageGateway ?? MapManager.instance.storageGateway;

  bool get hasOpenMaps => _mapManager.hasOpenMaps;

  Future<void> createNewMap({String? name}) async {
    final finalName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : NameGenerator.generate();
    _log.info('createNewMap name=$finalName');

    if (_storageGateway?.isInitialized == true) {
      final descriptor = await _storageGateway!.createMap(finalName);
      _mapManager.openMap(
        descriptor.storagePath,
        descriptor.name,
        mapId: descriptor.id,
      );
    } else {
      final path = 'maps/$finalName.db';
      _mapManager.openMap(path, finalName);
    }
    notifyListeners();
  }

  void openMap(MapInfo map) {
    _log.info('openMap name=${map.name} path=${map.path}');
    _mapManager.openMap(map.path, map.name, mapId: map.id);
  }

  Future<bool> openCentFile(String centFilePath, String name) {
    _log.info('openCentFile name=$name centPath=$centFilePath');
    return _mapManager.openCentFile(centFilePath, name);
  }

  Future<void> deleteMaps(List<MapInfo> mapsToDelete) async {
    if (mapsToDelete.isEmpty) return;
    _log.info('deleteMaps count=${mapsToDelete.length}');

    for (final map in mapsToDelete) {
      await _mapManager.closeByPath(map.path, saveState: false);
    }

    if (_storageGateway?.isInitialized == true) {
      for (final map in mapsToDelete) {
        await _storageGateway!.deleteMap(map.id);
      }
    }
    notifyListeners();
  }

  Future<MapDescriptor?> renameMap(MapInfo map, String newName) async {
    if (newName == map.name) return null;
    _log.info('renameMap old=${map.name} new=$newName');

    await _mapManager.closeByPath(map.path, saveState: true);

    if (_storageGateway?.isInitialized == true) {
      final updated = await _storageGateway!.renameMap(map.id, newName);
      notifyListeners();
      return updated;
    }
    notifyListeners();
    return null;
  }

  Future<List<MapInfo>> fetchRecentMaps() => MapScanner.getRecentMaps();

  Future<List<MapInfo>> fetchProjectMaps() => MapScanner.getProjectMaps();
}
