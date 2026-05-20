import 'dart:io';
import 'package:flutter/material.dart';
import '../../../src/rust/bridge/api.dart';
import '../store/graph_data_controller.dart';
import 'theme_manager.dart';
import 'node_render_state.dart';

class TabSession {
  final String id;
  final String storagePath;
  final String name;
  AppHandle? handle;
  ThemeController? themeController;
  GraphDataController? dataController;
  NodeRenderState? nodeRenderState;
  final ValueNotifier<String> toolModeNotifier = ValueNotifier('select');
  bool isInitialized = false;

  Future<void>? _initFuture;

  TabSession({
    required this.id,
    required this.storagePath,
    required this.name,
  });

  Future<void> initialize(ThemeData globalTheme) {
    return _initFuture ??= _doInitialize(globalTheme).catchError((e) {
      _initFuture = null;
      throw e;
    });
  }

  Future<void> _doInitialize(ThemeData globalTheme) async {
    final file = File(storagePath);
    final directory = file.parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final activeHandle = await AppHandle.newInstance(
      storagePath: storagePath,
      name: name,
    );
    handle = activeHandle;
    final tc = ThemeController(activeHandle);
    themeController = tc;
    final dc = GraphDataController(activeHandle, tc);
    dataController = dc;
    nodeRenderState = NodeRenderState(dc);
    
    await tc.initialize(globalTheme);
    await dc.loadGraph();
    isInitialized = true;
  }

  void dispose() {
    themeController?.dispose();
    dataController?.dispose();
    nodeRenderState?.dispose();
    toolModeNotifier.dispose();
    handle?.close();
  }
}

class WorkspaceTabsController extends ChangeNotifier {
  final List<TabSession> _tabs = [];
  int _activeIndex = 0;

  WorkspaceTabsController({required String initialPath, required String initialName}) {
    addTab(initialPath, initialName);
  }

  List<TabSession> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;

  TabSession get activeSession => _tabs[_activeIndex];

  void addTab(String storagePath, String name) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${storagePath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final newSession = TabSession(
      id: id,
      storagePath: storagePath,
      name: name,
    );
    _tabs.add(newSession);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _activeIndex) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least one tab open
    final closedSession = _tabs.removeAt(index);
    closedSession.dispose();

    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }
}
