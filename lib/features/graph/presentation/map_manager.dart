import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/shared/utils/name_generator.dart';
import 'map_storage_gateway.dart';
import 'workspace_tabs_controller.dart';

class MapManager extends ChangeNotifier {
  static final MapManager instance = MapManager._();
  MapManager._();

  final Logger _log = Logger('MapManager');
  WorkspaceTabsController? _tabsController;
  MapStorageGateway? _storageGateway;
  VoidCallback? _onAllTabsClosed;

  MapStorageGateway? get storageGateway => _storageGateway;
  set storageGateway(MapStorageGateway? gateway) => _storageGateway = gateway;

  WorkspaceTabsController? get activeTabsController => _tabsController;

  WorkspaceTabsController get tabsController {
    assert(_tabsController != null, 'No maps are open');
    return _tabsController!;
  }

  bool get hasOpenMaps =>
      _tabsController != null && _tabsController!.tabs.isNotEmpty;

  Future<void> flushAndCloseAll() async {
    _log.info('flushAndCloseAll via MapManager');
    final controller = _tabsController;
    if (controller != null) {
      await controller.flushAndCloseAll();
    }
  }

  bool isPathOpen(String storagePath) {
    if (_tabsController == null) return false;
    final canonicalTarget = p.canonicalize(storagePath);
    return _tabsController!.tabs.any(
      (t) => p.canonicalize(t.storagePath) == canonicalTarget,
    );
  }

  Future<void> createAndOpenMap({String? name}) async {
    final finalName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : NameGenerator.generate();
    _log.info('createAndOpenMap name=$finalName');

    if (_storageGateway?.isInitialized == true) {
      final descriptor = await _storageGateway!.createMap(finalName);
      openMap(
        descriptor.storagePath,
        descriptor.name,
        mapId: descriptor.id,
      );
    } else {
      final path = 'maps/$finalName.db';
      openMap(path, finalName);
    }
  }

  bool openMap(String storagePath, String name, {String? mapId}) {
    _log.info('openMap name=$name path=$storagePath id=$mapId');
    final id = mapId ?? p.basenameWithoutExtension(storagePath);
    if (_storageGateway?.isInitialized == true) {
      _storageGateway!.touchMap(id);
    }

    if (_tabsController != null) {
      final canonicalTarget = p.canonicalize(storagePath);
      final existingIndex = _tabsController!.tabs.indexWhere(
        (t) => p.canonicalize(t.storagePath) == canonicalTarget,
      );
      if (existingIndex >= 0) {
        _log.info('Map already open at tab $existingIndex, selecting it');
        _tabsController!.selectTab(existingIndex);
        notifyListeners();
        return true;
      }
      _tabsController!.addTab(storagePath, name);
      notifyListeners();
      return false;
    }

    _tabsController = WorkspaceTabsController(
      initialPath: storagePath,
      initialName: name,
    );
    _tabsController!.addListener(_onTabsChanged);
    notifyListeners();
    return false;
  }

  void _onTabsChanged() {
    notifyListeners();
    if (_tabsController != null && _tabsController!.tabs.isEmpty) {
      _log.info('All tabs closed');
      final controller = _tabsController;
      _tabsController = null;
      controller?.removeListener(_onTabsChanged);
      Future.microtask(() {
        controller?.dispose();
      });
      _onAllTabsClosed?.call();
    }
  }

  void closeTab(int index, {bool saveState = true}) {
    _tabsController?.closeTab(index, saveState: saveState);
  }

  Future<void> closeByPath(String storagePath, {bool saveState = true}) async {
    if (_tabsController == null) return;
    final canonicalTarget = p.canonicalize(storagePath);
    final index = _tabsController!.tabs.indexWhere(
      (t) => p.canonicalize(t.storagePath) == canonicalTarget,
    );
    if (index >= 0) {
      _log.info('closeByPath closing tab $index for $storagePath saveState=$saveState');
      await _tabsController!.closeTab(index, saveState: saveState);
    }
  }

  Future<bool> openCentFile(String centFilePath, String name) async {
    _log.info('openCentFile name=$name centPath=$centFilePath');

    final storagePath = await AppPaths.resolveMapPath(name);
    final id = p.basenameWithoutExtension(storagePath);
    if (_storageGateway?.isInitialized == true) {
      _storageGateway!.touchMap(id);
    }

    if (_tabsController != null) {
      final canonicalTarget = p.canonicalize(storagePath);
      final existingIndex = _tabsController!.tabs.indexWhere(
        (t) => p.canonicalize(t.storagePath) == canonicalTarget,
      );
      if (existingIndex >= 0) {
        _log.info('Map already open at tab $existingIndex, selecting it');
        _tabsController!.selectTab(existingIndex);
        notifyListeners();
        return true;
      }
      _tabsController!.addTab(storagePath, name, centFilePath: centFilePath);
      notifyListeners();
      return false;
    }

    _tabsController = WorkspaceTabsController(
      initialPath: storagePath,
      initialName: name,
      initialCentFilePath: centFilePath,
    );
    _tabsController!.addListener(_onTabsChanged);
    notifyListeners();
    return false;
  }

  void closeAll() {
    _log.info('closeAll');
    _tabsController?.removeListener(_onTabsChanged);
    _tabsController?.dispose();
    _tabsController = null;
    notifyListeners();
  }

  set onAllTabsClosed(VoidCallback? callback) {
    _onAllTabsClosed = callback;
  }

  @visibleForTesting
  set tabsControllerForTesting(WorkspaceTabsController? controller) {
    _tabsController = controller;
  }

  @override
  void dispose() {
    _tabsController?.removeListener(_onTabsChanged);
    _tabsController?.dispose();
    _tabsController = null;
    super.dispose();
  }

}
