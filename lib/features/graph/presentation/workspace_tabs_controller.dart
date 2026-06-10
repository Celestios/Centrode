import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../src/rust/bridge/api.dart';
import '../../../src/rust/domain/base_models.dart' show ViewportState;
import '../store/graph_data_controller.dart';
import 'graph_presentation_notifier.dart';
import 'theme_manager.dart';
import 'node_render_state.dart';
import 'viewport_state.dart';
import 'strategies/node_layout_strategy.dart';
import 'strategies/node_style_strategy.dart';
import 'style_manager.dart';

class TabSession extends ChangeNotifier {
  final String id;
  final String storagePath;
  final String name;
  AppHandle? handle;
  ThemeController? themeController;
  GraphDataController? dataController;
  GraphPresentationNotifier? presentationNotifier;
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
    final dc = dataController;
    if (vp != null && dc != null) {
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

      try {
        await dc.saveViewportState(state);
      } catch (e) {
        debugPrint('Failed to save viewport state for session $name: $e');
      }
    }
  }

  final ValueNotifier<String> toolModeNotifier = ValueNotifier('select');
  final ValueNotifier<String> brushColorNotifier = ValueNotifier('#00E5FF');
  final ValueNotifier<double> brushThicknessNotifier = ValueNotifier(4.0);
  final ValueNotifier<String> brushTypeNotifier = ValueNotifier('pen');
  final ValueNotifier<bool> showLeftPanel = ValueNotifier(true);
  final ValueNotifier<bool> showRightPanel = ValueNotifier(true);
  final ValueNotifier<bool> showBottomPanel = ValueNotifier(true);
  bool isInitialized = false;

  Future<void>? _initFuture;

  TabSession({required this.id, required this.storagePath, required this.name});

  Future<void> initialize(ThemeData globalTheme) {
    return _initFuture ??= _doInitialize(globalTheme).catchError((e) {
      _initFuture = null;
      throw e;
    });
  }

  Future<void> _doInitialize(ThemeData globalTheme) async {
    String resolvedPath = storagePath;
    if (!p.isAbsolute(storagePath)) {
      final appSupportDir = await getApplicationSupportDirectory();
      resolvedPath = p.join(appSupportDir.path, storagePath);
    }

    final file = File(resolvedPath);
    final directory = file.parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final activeHandle = await AppHandle.newInstance(
      storagePath: resolvedPath,
      name: name,
    );
    handle = activeHandle;
    final tc = ThemeController(activeHandle);
    themeController = tc;
    final dc = GraphDataController(activeHandle);
    dataController = dc;
    presentationNotifier = GraphPresentationNotifier(dc);
    nodeRenderState = NodeRenderState(dc);

    final styleManager = StyleManager(dc.store);
    dc.sizeCalculator = NodeLayoutStrategy.calculateSize;
    dc.styleResolver = (node) => NodeStyleStrategy.resolveStyle(node);
    dc.styleUpdater = styleManager;

    tc.addListener(() {
      final newTheme = tc.currentGraphTheme;
      styleManager.setTheme(newTheme);
      styleManager.updateAllStyles(dc.store.nodes, dc.store.relations);
      dc.triggerUpdate();
    });

    await tc.initialize(globalTheme);
    // Seeding initial theme style
    styleManager.setTheme(tc.currentGraphTheme);
    styleManager.updateAllStyles(dc.store.nodes, dc.store.relations);

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
    presentationNotifier?.dispose();
    nodeRenderState?.dispose();
    toolModeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
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

  WorkspaceTabsController({
    required String initialPath,
    required String initialName,
  }) {
    addTab(initialPath, initialName);
  }

  List<TabSession> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;

  TabSession get activeSession => _tabs[_activeIndex];

  void addTab(String storagePath, String name) {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${storagePath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final newSession = TabSession(id: id, storagePath: storagePath, name: name);
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
