import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'graph_data_query.dart';
import '../models/models.dart';
import 'command_processor.dart';
import '../presentation/theme_manager.dart';
import 'package:mycelium/src/rust/bridge/api.dart' as rust;
import 'package:mycelium/src/rust/domain/base_models.dart'
    show BoundingBox, Comment, ViewportState;
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/tags.dart';

import 'modules/graph_store.dart';
import 'modules/graph_spatial.dart';
import 'modules/graph_sync_engine.dart';
import 'modules/graph_node_mutations.dart';
import 'modules/graph_relation_mutations.dart';
import 'modules/graph_property_mutations.dart';
import 'package:mycelium/features/graph/presentation/style_manager.dart';

/// High-level orchestrator utilizing Clean Class Composition.
///
/// This controller acts as the central coordinator (Facade) for the graph state:
/// - **GraphStore**: Encapsulates $O(1)$ in-memory storage.
/// - **GraphSpatial**: Manages viewport culling and reactive geometry.
/// - **GraphSyncEngine**: Handles FFI sync, DB stream, and hydration.
/// - **GraphNodeMutations**: Handles node mutations (create, delete, move, resize).
/// - **GraphRelationMutations**: Handles relation mutations (create).
/// - **GraphPropertyMutations**: Handles property mutations (text, styling).
class GraphDataController extends ChangeNotifier implements GraphDataQuery {
  final Logger _log = Logger('GraphDataController');

  // ===========================================================================
  // Domain Modules (Composition)
  // ===========================================================================

  late final GraphStore store;
  late final GraphSpatial spatial;
  late final GraphSyncEngine syncEngine;
  late final StyleManager styleManager;

  late final GraphNodeMutations nodeMutations;
  late final GraphRelationMutations relationMutations;
  late final GraphPropertyMutations propertyMutations;

  final ThemeController themeController;

  // ===========================================================================
  // State Flags & Stream
  // ===========================================================================

  final StreamController<GraphEntityUpdate> _entityUpdateController =
      StreamController<GraphEntityUpdate>.broadcast();

  @override
  Stream<GraphEntityUpdate> get onEntityUpdate =>
      _entityUpdateController.stream;

  void publishUpdate(GraphEntityUpdate update) {
    _entityUpdateController.add(update);
  }

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  void Function(String) get onError => _handleError;

  // ===========================================================================
  // Backward Compatibility & Facade Mappings
  // ===========================================================================

  @override
  SpatialHashGrid get spatialGrid => spatial.spatialGrid;

  /// Alias for [spatialGrid] for backward compatibility.
  SpatialHashGrid get spatialHash => spatial.spatialGrid;

  @override
  Map<String, UiNode> get nodeLookup => store.nodeLookup;

  @override
  Map<String, UiRelation> get relationLookup => store.relationLookup;

  @override
  Iterable<UiRelation> get relations => store.relations;

  Iterable<UiNode> get nodesIterable => store.nodes;

  @override
  ValueNotifier<BoundingBox> get canvasBounds => syncEngine.canvasBounds;

  ViewportState? getSavedViewportState() {
    return syncEngine.savedViewportState;
  }

  void updateSavedViewportState(ViewportState state) {
    syncEngine.updateSavedViewportState(state);
  }

  // ===========================================================================
  // Constructor
  // ===========================================================================

  /// Creates a new GraphDataController and initializes its domain modules.
  GraphDataController(rust.AppHandle apiHandle, this.themeController) {
    store = GraphStore();
    spatial = GraphSpatial();
    syncEngine = GraphSyncEngine(
      controller: this,
      api: apiHandle,
      processor: CommandProcessor(onError: _handleError),
      themeController: themeController,
    );
    nodeMutations = GraphNodeMutations(this);
    relationMutations = GraphRelationMutations(this);
    propertyMutations = GraphPropertyMutations(this);
    styleManager = StyleManager(store);

    themeController.addListener(_onThemeChanged);

    _log.info(
      'GraphDataController initialized: Domain modules successfully composed.',
    );
  }

  void _onThemeChanged() {
    final newTheme = themeController.currentGraphTheme;
    styleManager.setTheme(newTheme);
    styleManager.updateAllStyles(store.nodes, store.relations);
    notifyListeners();
  }

  // ===========================================================================
  // Error Handling
  // ===========================================================================

  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    errorMessage = msg;
    notifyListeners();
  }

  void triggerUpdate() {
    notifyListeners();
  }

  // ===========================================================================
  // Delegator Methods (Public API Contract)
  // ===========================================================================

  Future<void> loadGraph() async {
    isLoading = true;
    notifyListeners();
    final stopwatch = Stopwatch()..start();
    _log.info('loadGraph: Initiating FFI request to load graph state.');

    try {
      await syncEngine.loadGraph();
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

  // FFI Sync Actions
  void flushSync() => syncEngine.flushSync();
  Future<void> flush() => syncEngine.flush();
  Future<void> undo() async {
    await syncEngine.undo();
    notifyListeners();
  }

  Future<void> redo() async {
    await syncEngine.redo();
    notifyListeners();
  }

  // Node Mutations
  String createNode(UiNodes type, Offset position) =>
      nodeMutations.createNode(type, position);

  Future<void> deleteNode(String id) => nodeMutations.deleteNode(id);

  void updateNodePosition(String id, Offset newPosition) =>
      nodeMutations.updateNodePosition(id, newPosition);

  void updateNodeWidth(String id, double leftEdge, double rightEdge) =>
      nodeMutations.updateNodeWidth(id, leftEdge, rightEdge);

  void toggleNodeExpansion(String id) => nodeMutations.toggleNodeExpansion(id);

  // Relation Mutations
  void createRelation(
    String fromId,
    String toId, {
    String? fromSide,
    String? toSide,
  }) => relationMutations.createRelation(
    fromId,
    toId,
    fromSide: fromSide,
    toSide: toSide,
  );

  Future<void> deleteRelation(String id) =>
      relationMutations.deleteRelation(id);

  void updateRelationLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    String? fromSide,
    String? toSide,
    String? strategyType,
  }) => relationMutations.updateRelationLayout(
    id,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    fromSide: fromSide,
    toSide: toSide,
    strategyType: strategyType,
  );

  // Property Mutations
  void commitEntityText(String id, String newText, {String? originalText}) =>
      propertyMutations.commitEntityText(
        id,
        newText,
        originalText: originalText,
      );

  void updateEntityTextLive(String id, String newText) =>
      propertyMutations.updateEntityTextLive(id, newText);

  void updateNodeStyle(String id, NodeStyle newStyle) =>
      propertyMutations.updateNodeStyle(id, newStyle);

  void updateNodeTags(String id, List<Tag> newTags) =>
      propertyMutations.updateNodeTags(id, newTags);

  void updateNodeComments(String id, List<Comment> newComments) =>
      propertyMutations.updateNodeComments(id, newComments);

  // Global Tags Manager CRUD
  Future<List<Tag>> getAllTags() => propertyMutations.getAllTags();
  Future<void> createTag(Tag tag) => propertyMutations.createTag(tag);
  Future<void> updateTag(Tag tag) => propertyMutations.updateTag(tag);
  Future<void> deleteTag(String tagKey) => propertyMutations.deleteTag(tagKey);

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void dispose() {
    _log.fine('Disposing GraphDataController and dismantling domain modules.');
    themeController.removeListener(_onThemeChanged);
    _entityUpdateController.close();
    syncEngine.dispose();
    spatial.dispose();
    super.dispose();
  }
}
