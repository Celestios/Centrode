import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../src/rust/bridge/api.dart';
import '../../../src/rust/domain/base_models.dart' show ViewportState;
import '../store/graph_data_controller.dart';
import 'theme_manager.dart';
import 'node_render_state.dart';
import 'viewport_state.dart';

class TabSession extends ChangeNotifier {
  final String id;
  final String storagePath;
  final String name;
  AppHandle? handle;
  ThemeController? themeController;
  GraphDataController? dataController;
  NodeRenderState? nodeRenderState;

  ViewportController? _viewportController;
  Timer? _debounceTimer;

  ViewportController? get viewportController => _viewportController;

  set viewportController(ViewportController? vp) {
    if (_viewportController == vp) return;
    _viewportController?.transformController.removeListener(_onViewportChanged);
    _viewportController = vp;
    _viewportController?.transformController.addListener(_onViewportChanged);
  }

  void _onViewportChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      saveViewportState();
    });
  }

  Future<void> saveViewportState() async {
    _debounceTimer?.cancel();
    final vp = _viewportController;
    final h = handle;
    if (vp != null && h != null) {
      final matrix = vp.transformController.value;
      final xOffset = matrix.getTranslation().x;
      final yOffset = matrix.getTranslation().y;
      final zoomLevel = matrix.getMaxScaleOnAxis();
      const activeView = "canvas";

      final state = ViewportState(
        xOffset: xOffset,
        yOffset: yOffset,
        zoomLevel: zoomLevel,
        activeView: activeView,
      );

      dataController?.updateSavedViewportState(state);

      try {
        await h.updateViewportState(state: state);
      } catch (e) {
        debugPrint('Failed to save viewport state for session $name: $e');
      }
    }
  }

  final ValueNotifier<String> toolModeNotifier = ValueNotifier('select');
  final ValueNotifier<bool> showLeftPanel = ValueNotifier(true);
  final ValueNotifier<bool> showRightPanel = ValueNotifier(true);
  final ValueNotifier<bool> showBottomPanel = ValueNotifier(true);
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
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _viewportController?.transformController.removeListener(_onViewportChanged);
    themeController?.dispose();
    dataController?.dispose();
    nodeRenderState?.dispose();
    toolModeNotifier.dispose();
    showLeftPanel.dispose();
    showRightPanel.dispose();
    showBottomPanel.dispose();
    _viewportController = null;
    handle?.close();
    super.dispose();
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
      final prevSession = _tabs[_activeIndex];
      prevSession.saveViewportState(); // Fire-and-forget

      _activeIndex = index;
      notifyListeners();
    }
  }

  Future<void> closeTab(int index) async {
    if (_tabs.length <= 1) return; // Keep at least one tab open
    final closedSession = _tabs[index];
    await closedSession.saveViewportState();

    _tabs.removeAt(index);
    if (index < _activeIndex) {
      _activeIndex--;
    } else if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();

    closedSession.dispose();
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }
}
