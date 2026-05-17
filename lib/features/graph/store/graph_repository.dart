import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'graph_data_query.dart';
import '../presentation/view_state.dart';
import '../models/models.dart';
import '../state/command_processor.dart';
import '../presentation/theme_manager.dart';
import 'package:mycelium/src/rust/bridge/api.dart' as rust;
import 'package:mycelium/features/graph/presentation/style_resolver.dart';
import 'mixins/graph_store_mixin.dart';
import 'mixins/graph_spatial_mixin.dart';
import 'mixins/graph_sync_base_mixin.dart';
import 'mixins/graph_sync_nodes_mixin.dart';
import 'mixins/graph_sync_relations_mixin.dart';
import 'mixins/graph_sync_properties_mixin.dart';

/// High-level orchestrator utilizing Linearized Mixin Composition.
///
/// This controller acts as a dependency injector and state flag manager,
/// delegating all core functionality to specialized mixins:
/// - **GraphStoreMixin**: Tier 1 - Canonical O(1) in-memory storage
/// - **GraphSpatialMixin**: Tier 2 - Viewport culling and reactive geometry
/// - **GraphSyncBaseMixin**: Tier 3 Base - FFI coordination foundation
/// - **GraphNodeMutationsMixin**: Tier 3 - Node mutation operations
/// - **GraphRelationMutationsMixin**: Tier 3 - Relation mutation operations
/// - **GraphPropertyMutationsMixin**: Tier 3 - Property mutation operations
///
/// ## Architecture Overview
///
/// The Linearized Mixin Composition pattern ensures a clear linearization
/// order for method resolution:
/// ```
/// GraphDataController → GraphPropertyMutationsMixin → GraphRelationMutationsMixin →
/// GraphNodeMutationsMixin → GraphSyncBaseMixin → GraphSpatialMixin →
/// GraphStoreMixin → ChangeNotifier
/// ```
///
/// ## Responsibilities
///
/// 1. **Dependency Injection**: Initializes `late` fields required by mixins
/// 2. **State Flags**: Manages `isLoading` and `errorMessage` for UI binding
/// 3. **Lifecycle Management**: Coordinates disposal across all mixins
///
/// ## Performance Characteristics
///
/// - Node/Relation lookup: O(1) via [GraphStoreMixin]
/// - Viewport culling: O(1) via [GraphSpatialMixin]
/// - Position updates: Debounced 300ms via [GraphNodeMutationsMixin]
///
/// See also:
/// - [GraphStoreMixin] for data storage
/// - [GraphSpatialMixin] for spatial operations
/// - [GraphSyncBaseMixin] for FFI foundation
/// - [GraphNodeMutationsMixin] for node operations
/// - [GraphRelationMutationsMixin] for relation operations
/// - [GraphPropertyMutationsMixin] for property operations
class GraphDataController extends ChangeNotifier
    with
        GraphStoreMixin,
        GraphSpatialMixin,
        GraphSyncBaseMixin,
        GraphNodeMutationsMixin,
        GraphRelationMutationsMixin,
        GraphPropertyMutationsMixin
    implements GraphDataQuery {
  final Logger _log = Logger('GraphDataController'); // [NEW]

  // ===========================================================================
  // State Flags
  // ===========================================================================

  /// Indicates if a graph loading operation is in progress.
  @override
  bool isLoading = false;

  /// Current error message, if any.
  @override
  String? errorMessage;

  // ===========================================================================
  // Backward Compatibility Getters
  // ===========================================================================

  /// Alias for [spatialGrid] for backward compatibility.
  ///
  /// The original API used `spatialHash` but the mixin uses `spatialGrid`.
  /// This getter maintains the original API contract.
  SpatialHashGrid get spatialHash => spatialGrid;

  /// Alias for [viewStates] for backward compatibility.
  ///
  /// The original API used `allNodeViewStates` but the mixin uses `viewStates`.
  /// This getter maintains the original API contract.
  Map<String, NodeViewState> get allNodeViewStates => viewStates;

  // ===========================================================================
  // Constructor
  // ===========================================================================

  /// Creates a new GraphDataController with the given API handle and theme controller.
  ///
  /// Initializes all `late` contracts for [GraphSyncMixin] to prevent
  /// initialization crashes when mixin methods are called.
  GraphDataController(rust.AppHandle apiHandle, ThemeController theme) {
    // Fulfill the 'late' contracts for GraphSyncMixin
    api = apiHandle;
    themeController = theme;
    onError = _handleError;
    processor = CommandProcessor(onError: _handleError);
    styleManager = StyleManager(this);

    theme.addListener(_onThemeChanged);

    _log.info(
      'GraphDataController initialized: Late contracts (API, Theme, Processor) successfully bound.',
    );
  }

  void _onThemeChanged() {
    final newTheme = themeController.currentGraphTheme;
    styleManager.setTheme(newTheme);
    styleManager.updateAllStyles(nodeLookup.values, relationLookup.values);
    notifyListeners();
  }

  // ===========================================================================
  // Error Handling
  // ===========================================================================

  /// Handles errors from sub-services and notifies listeners.
  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    errorMessage = msg;
    notifyListeners();
  }

  /// Triggers a manual update for listeners.
  void triggerUpdate() {
    notifyListeners();
  }

  // ===========================================================================
  // Graph Loading
  // ===========================================================================

  /// Loads the graph from the database.
  ///
  /// Wraps [GraphSyncMixin.loadGraph] with loading state management.
  /// Sets [isLoading] flag during the operation for UI binding.
  @override
  Future<void> loadGraph() async {
    isLoading = true;
    notifyListeners();
    final stopwatch = Stopwatch()..start();
    _log.info('loadGraph: Initiating FFI request to load graph state.');

    try {
      await super.loadGraph(); // Dispatches to GraphSyncMixin
      stopwatch.stop();
      _log.info(
        'loadGraph: Completed successfully in ${stopwatch.elapsedMilliseconds}ms.',
      );
    } catch (e) {
      stopwatch.stop();
      _log.severe(
        'loadGraph: Failed after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  /// Disposes all resources held by this controller.
  ///
  /// Ensures proper cleanup order:
  /// 1. Flush and dispose sync resources (pending commands)
  /// 2. Dispose spatial resources (view states, movement notifier)
  /// 3. Dispose base ChangeNotifier
  @override
  void dispose() {
    _log.fine('Disposing GraphDataController and dismantling mixin chain.');
    disposeSync();
    disposeSpatial();
    super.dispose();
  }
}
