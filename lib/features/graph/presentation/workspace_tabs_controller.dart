import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/traceable_notifier.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/shared/utils/app_paths.dart';
import '../../../src/rust/bridge/api.dart';
import '../../../src/rust/domain/base_models.dart' show ViewportState;
import '../store/graph_data_query_controller.dart';
import '../store/graph_data_query.dart';
import '../store/command_queue_processor.dart';
import '../store/graph_api.dart';
import 'theme_manager.dart';
import 'node_render_state.dart';
import 'viewport_state.dart';
import 'strategies/node_layout_strategy.dart';
import 'strategies/node_style_strategy.dart';
import 'style_manager.dart';

class TabSession extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'TabSession';
  final Logger _log = Logger('TabSession');
  final String id;
  final String storagePath;
  final String name;
  final String? centFilePath;
  GraphApi? handle;
  ThemeController? themeController;
  GraphDataQueryController? queryController;
  CommandQueueProcessor? commandProcessor;
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
    _log.fine('saveViewportState for session $name');
    _debounceTimer?.cancel();
    final vp = _viewportController;
    final api = handle;
    if (vp != null && api != null) {
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
        await api.updateViewportState(state: state);
      } catch (e) {
        debugPrint('Failed to save viewport state for session $name: $e');
      }
    }
  }

  final ValueNotifier<String> toolModeNotifier = ValueNotifier('select');
  final ValueNotifier<String> brushColorNotifier = ValueNotifier('#00E5FF');
  final ValueNotifier<double> brushThicknessNotifier = ValueNotifier(4.0);
  final ValueNotifier<String> brushTypeNotifier = ValueNotifier('pen');

  // Ribbon View Modes & Settings Notifiers
  final ValueNotifier<String> currentViewNotifier = ValueNotifier('canvas');
  final ValueNotifier<String> relationLabelModeNotifier = ValueNotifier('auto');

  // Ribbon & Global Format Defaults Notifiers
  final ValueNotifier<String> defaultTextFormatNotifier = ValueNotifier('Markdown');
  final ValueNotifier<String> defaultNodeShapeNotifier = ValueNotifier('Rounded Rectangle');
  final ValueNotifier<String> defaultRelationTypeNotifier = ValueNotifier('Directed Arrow');

  void setToolMode(String mode) {
    if (toolModeNotifier.value != mode) {
      toolModeNotifier.value = mode;
    }
  }

  void setBrushColor(String color) {
    if (brushColorNotifier.value != color) {
      brushColorNotifier.value = color;
    }
  }

  void setBrushThickness(double thickness) {
    if (brushThicknessNotifier.value != thickness) {
      brushThicknessNotifier.value = thickness;
    }
  }

  void setBrushType(String type) {
    if (brushTypeNotifier.value != type) {
      brushTypeNotifier.value = type;
    }
  }

  final ValueNotifier<bool> showLeftPanel = ValueNotifier(true);
  final ValueNotifier<bool> showRightPanel = ValueNotifier(true);
  final ValueNotifier<bool> showBottomPanel = ValueNotifier(true);
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);
  VoidCallback? _themeListener;
  StreamSubscription<GraphEntityUpdate>? _querySub;
  final DeferredGraphApi _deferredApi = DeferredGraphApi();

  Future<void>? _initFuture;

  TabSession({
    required this.id,
    required this.storagePath,
    required this.name,
    this.centFilePath,
  }) {
    handle = _deferredApi;
    final tc = ThemeController(_deferredApi);
    themeController = tc;
    final qc = GraphDataQueryController(_deferredApi);
    queryController = qc;
    final processor = CommandQueueProcessor(_deferredApi, qc);
    commandProcessor = processor;
    nodeRenderState = NodeRenderState(qc, processor);

    final styleManager = StyleManager(qc.store);
    final layoutStrategy = DefaultNodeLayoutStrategy();
    processor.sizeCalculator = layoutStrategy.calculateSize;
    processor.styleResolver = (node) => NodeStyleStrategy.resolveStyle(node);
    processor.styleUpdater = styleManager;

    _themeListener = () {
      final newTheme = tc.currentGraphTheme;
      styleManager.setTheme(newTheme);
      styleManager.updateAllStyles(qc.store.nodes, qc.store.relations);
      qc.triggerUpdate();
    };
    tc.addListener(_themeListener!);

    _querySub = qc.onEntityUpdate.listen((_) {
      notifyListeners();
    });
  }

  Future<void> initialize(ThemeData globalTheme) {
    return _initFuture ??= _doInitialize(globalTheme).catchError((e) {
      _initFuture = null;
      throw e;
    });
  }

  Future<void> _doInitialize(ThemeData globalTheme) async {
    _log.info('Initializing TabSession name=$name path=$storagePath');
    String resolvedPath = storagePath;
    if (!p.isAbsolute(storagePath)) {
      resolvedPath = await AppPaths.resolveMapPath(
        p.basenameWithoutExtension(storagePath),
      );
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
    final wrapper = RustAppHandleWrapper(activeHandle);
    _deferredApi.attach(wrapper);

    if (centFilePath != null) {
      final attachmentDir = p.join(
        directory.path,
        'attachments',
        p.basenameWithoutExtension(centFilePath!),
      );
      if (!Directory(attachmentDir).existsSync()) {
        Directory(attachmentDir).createSync(recursive: true);
      }
      await wrapper.loadMapFromFile(
        filePath: centFilePath!,
        attachmentDir: attachmentDir,
      );
    }

    final tc = themeController!;
    final qc = queryController!;
    final processor = commandProcessor!;

    await tc.initialize(globalTheme);
    // Seeding initial theme style
    final styleManager = processor.styleUpdater as StyleManager?;
    styleManager?.setTheme(tc.currentGraphTheme);
    styleManager?.updateAllStyles(qc.store.nodes, qc.store.relations);

    await processor.loadGraph();
    isInitialized.value = true;
    _log.info('TabSession initialized successfully');
    notifyListeners();
  }

  bool get canUndo => commandProcessor?.canUndo ?? false;
  bool get canRedo => commandProcessor?.canRedo ?? false;
  int get undoCount => commandProcessor?.undoCount ?? 0;
  int get redoCount => commandProcessor?.redoCount ?? 0;

  Future<void> undo() async {
    await commandProcessor?.undo();
    notifyListeners();
  }

  Future<void> redo() async {
    await commandProcessor?.redo();
    notifyListeners();
  }


    Future<void> close() async {
    _log.info('Closing TabSession name=$name path=$storagePath');
    _debounceTimer?.cancel();
    final h = handle;
    if (h != null) {
      await h.close();
    }
  }

  /// Flushes pending mutations, saves viewport state, and closes the handle.
  Future<void> flushAndClose({bool saveState = true}) async {
    _log.info('flushAndClose TabSession name=$name path=$storagePath');
    _debounceTimer?.cancel();
    if (saveState) {
      await saveViewportState();
    }
    final cp = commandProcessor;
    if (cp != null) {
      await cp.flush();
    }
    await close();
  }

  @override
  void dispose() {
    _log.info('Disposing TabSession name=$name');
    _debounceTimer?.cancel();
    _viewportController?.transformController.removeListener(_onViewportChanged);
    if (_themeListener != null) {
      themeController?.removeListener(_themeListener!);
      _themeListener = null;
    }
    _querySub?.cancel();
    _querySub = null;
    themeController?.dispose();
    queryController?.dispose();
    commandProcessor?.dispose();
    nodeRenderState?.dispose();
    toolModeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
    currentViewNotifier.dispose();
    relationLabelModeNotifier.dispose();
    defaultTextFormatNotifier.dispose();
    defaultNodeShapeNotifier.dispose();
    defaultRelationTypeNotifier.dispose();
    showLeftPanel.dispose();
    showRightPanel.dispose();
    showBottomPanel.dispose();
    isInitialized.dispose();
    _viewportController = null;
    _deferredApi.dispose();
    super.dispose();
  }
}

class WorkspaceTabsController extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'WorkspaceTabsController';
  final Logger _log = Logger('WorkspaceTabsController');
  final List<TabSession> _tabs = [];
  int _activeIndex = 0;
  bool _disposed = false;

  WorkspaceTabsController({
    required String initialPath,
    required String initialName,
    String? initialCentFilePath,
  }) {
    addTab(initialPath, initialName, centFilePath: initialCentFilePath);
  }

  List<TabSession> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;

  TabSession get activeSession => _tabs[_activeIndex];

  void addTab(String storagePath, String name, {String? centFilePath}) {
    _log.info('addTab name=$name');
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${storagePath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final newSession = TabSession(
      id: id,
      storagePath: storagePath,
      name: name,
      centFilePath: centFilePath,
    );
    _tabs.add(newSession);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void selectTab(int index) {
    _log.info('selectTab index=$index');
    if (index >= 0 && index < _tabs.length && index != _activeIndex) {
      final prevSession = _tabs[_activeIndex];
      prevSession.saveViewportState(); // Fire-and-forget

      _activeIndex = index;
      notifyListeners();
    }
  }

  Future<void> closeTab(int index, {bool saveState = true}) async {
    _log.info('closeTab index=$index saveState=$saveState');
    if (_tabs.isEmpty || index < 0 || index >= _tabs.length) return;

    final closedSession = _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _activeIndex = 0;
    } else if (index < _activeIndex) {
      _activeIndex--;
    } else if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();

    await closedSession.flushAndClose(saveState: saveState);
    closedSession.dispose();
  }

  /// Concurrently flushes mutations, saves viewports, and cleanly closes all open tabs.
  Future<void> flushAndCloseAll() async {
    _log.info('flushAndCloseAll tabs count=${_tabs.length}');
    final sessionsToClose = List<TabSession>.from(_tabs);
    _tabs.clear();
    _activeIndex = 0;
    notifyListeners();

    await Future.wait(
      sessionsToClose.map((session) async {
        await session.flushAndClose();
        session.dispose();
      }),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }
}
