import 'dart:async';
import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import 'graph_data_query.dart';
import 'graph_data_command.dart';
import 'spatial_index.dart';
import '../models/models.dart';
import 'command_processor.dart';
import 'package:mycelium/src/rust/bridge/api.dart' as rust;
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

import 'modules/graph_store.dart';
import 'modules/graph_spatial.dart';
import 'modules/graph_sync_engine.dart';
import 'modules/graph_node_mutations.dart';
import 'modules/graph_relation_mutations.dart';
import 'modules/graph_property_mutations.dart';
import 'modules/graph_template_mutations.dart';
import '../models/commands/graph_command_context.dart';

export '../models/commands/graph_command_context.dart'
    show GraphStyleUpdater;

/// High-level orchestrator utilizing Clean Class Composition.
///
/// This controller acts as the central coordinator (Facade) for the graph state:
/// - **GraphStore**: Encapsulates $O(1)$ in-memory storage.
/// - **GraphSpatial**: Manages viewport culling and reactive geometry.
/// - **GraphSyncEngine**: Handles FFI sync, DB stream, and hydration.
/// - **GraphNodeMutations**: Handles node mutations (create, delete, move, resize).
/// - **GraphRelationMutations**: Handles relation mutations (create).
/// - **GraphPropertyMutations**: Handles property mutations (text, styling).
class GraphDataController implements GraphDataQuery, GraphDataCommand, GraphCommandContext {
  final Logger _log = Logger('GraphDataController');

  // ===========================================================================
  // Domain Modules (Composition)
  // ===========================================================================

  @override
  late final GraphStore store;
  @override
  late final GraphSpatial spatial;
  late final GraphSyncEngine syncEngine;

  late final GraphNodeMutations nodeMutations;
  late final GraphRelationMutations relationMutations;
  late final GraphPropertyMutations propertyMutations;
  late final GraphTemplateMutations templateMutations;

  // Dependency Inversion Hooks
  ({Size size, int lineCount}) Function(UiNode, {bool isEditing})? sizeCalculator;
  NodeStyle Function(UiNode)? styleResolver;
  @override
  GraphStyleUpdater? styleUpdater;

  // ===========================================================================
  // State Flags & Stream
  // ===========================================================================

  final StreamController<GraphEntityUpdate> _entityUpdateController =
      StreamController<GraphEntityUpdate>.broadcast();

  @override
  Stream<GraphEntityUpdate> get onEntityUpdate =>
      _entityUpdateController.stream;

  @override
  void publishUpdate(GraphEntityUpdate update) {
    _entityUpdateController.add(update);
  }

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  void Function(String) get onError => _handleError;

  int _undoCount = 0;
  int _redoCount = 0;

  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  Future<void> updateHistoryStatus() async {
    try {
      _undoCount = await syncEngine.api.undoCount();
      _redoCount = await syncEngine.api.redoCount();
      triggerUpdate();
    } catch (e) {
      _log.warning('Failed to update history status: $e');
    }
  }

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
  BoundingBox get canvasBounds => syncEngine.canvasBounds;

  ViewportState? getSavedViewportState() {
    return syncEngine.savedViewportState;
  }

  void updateSavedViewportState(ViewportState state) {
    syncEngine.updateSavedViewportState(state);
  }

  // ===========================================================================
  // Sizing & Styling Wrapper Methods
  // ===========================================================================

  ({Size size, int lineCount}) calculateNodeSize(UiNode node, {bool isEditing = false}) {
    return sizeCalculator?.call(node, isEditing: isEditing) ?? (size: node.size, lineCount: node.lineCount);
  }

  NodeStyle resolveNodeStyle(UiNode node) {
    final resolver = styleResolver;
    if (resolver != null) {
      return resolver(node);
    }
    final ns = node.style;
    if (ns != null) {
      return ns;
    }
    throw StateError(
      'styleResolver must be configured on GraphDataController before resolving styles for unstyled nodes.',
    );
  }

  // ===========================================================================
  // Constructor
  // ===========================================================================

  /// Creates a new GraphDataController and initializes its domain modules.
  GraphDataController(
    rust.AppHandle apiHandle, {
    GraphStore? store,
    GraphSpatial? spatial,
    GraphSyncEngine? syncEngine,
    GraphNodeMutations? nodeMutations,
    GraphRelationMutations? relationMutations,
    GraphPropertyMutations? propertyMutations,
    GraphTemplateMutations? templateMutations,
  }) {
    this.store = store ?? GraphStore();
    this.spatial = spatial ?? GraphSpatial();
    this.syncEngine = syncEngine ??
        GraphSyncEngine(
          controller: this,
          api: apiHandle,
          processor: CommandProcessor(
            onError: _handleError,
            onQueueDrained: updateHistoryStatus,
          ),
        );
    this.nodeMutations = nodeMutations ?? GraphNodeMutations(this);
    this.relationMutations = relationMutations ?? GraphRelationMutations(this);
    this.propertyMutations = propertyMutations ?? GraphPropertyMutations(this);
    this.templateMutations = templateMutations ?? GraphTemplateMutations(this);

    _log.info(
      'GraphDataController initialized: Domain modules successfully composed.',
    );
  }

  // ===========================================================================
  // Error Handling
  // ===========================================================================

  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    errorMessage = msg;
    triggerUpdate();
  }

  @override
  void triggerUpdate() {
    publishUpdate(
      GraphEntityUpdate(id: '', tableName: '', type: GraphUpdateType.reset),
    );
  }

  // ===========================================================================
  // Delegator Methods (Public API Contract)
  // ===========================================================================

  @override
  Future<void> loadGraph() async {
    isLoading = true;
    triggerUpdate();
    final stopwatch = Stopwatch()..start();
    _log.info('loadGraph: Initiating FFI request to load graph state.');

    try {
      await syncEngine.loadGraph();
      await updateHistoryStatus();
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
      triggerUpdate();
    }
  }

  // FFI Sync Actions
  void flushSync() => syncEngine.flushSync();
  Future<void> flush() => syncEngine.flush();
  Future<void> undo() async {
    await syncEngine.undo();
    await updateHistoryStatus();
  }

  Future<void> redo() async {
    await syncEngine.redo();
    await updateHistoryStatus();
  }

  // Node Mutations
  String createNode(
    UiNodes type,
    Offset position, {
    List<String>? paths,
    String? brushType,
    double? brushThickness,
    String? brushColor,
    Size? size,
    Content? content,
  }) => nodeMutations.createNode(
    type,
    position,
    paths: paths,
    brushType: brushType,
    brushThickness: brushThickness,
    brushColor: brushColor,
    size: size,
    content: content,
  );

  @override
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
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) => relationMutations.createRelation(
    fromId,
    toId,
    fromSide: fromSide,
    toSide: toSide,
    verb: verb,
  );

  @override
  Future<void> deleteRelation(String id) =>
      relationMutations.deleteRelation(id);

  void updateRelationLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) => relationMutations.updateRelationLayout(
    id,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    fromSide: fromSide,
    toSide: toSide,
    strategyType: strategyType,
  );

  void updateRelationStyle(String id, RelationStyle newStyle) =>
      propertyMutations.updateRelationStyle(id, newStyle);

  @override
  void updateRelationsLayout(
    List<String> ids, {
    String? strategyType,
  }) => relationMutations.updateRelationsLayout(ids, strategyType: strategyType);

  // Property Mutations
  @override
  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent}) =>
      propertyMutations.commitEntityText(
        id,
        newTextOrContent,
        originalTextOrContent: originalTextOrContent,
      );

  @override
  void updateEntityTextLive(String id, dynamic newTextOrContent) =>
      propertyMutations.updateEntityTextLive(id, newTextOrContent);

  void updateNodeStyle(String id, NodeStyle newStyle) =>
      propertyMutations.updateNodeStyle(id, newStyle);

  @override
  void updateNodesStyle(List<String> ids, NodeStyle Function(NodeStyle style) updateFn) =>
      propertyMutations.updateNodesStyle(ids, updateFn);

  void updateNodeTags(String id, List<Tag> newTags) =>
      propertyMutations.updateNodeTags(id, newTags);

  void updateNodeComments(String id, List<Comment> newComments) =>
      propertyMutations.updateNodeComments(id, newComments);

  // Global Tags Manager CRUD
  Future<List<Tag>> getAllTags() => propertyMutations.getAllTags();
  Future<void> createTag(Tag tag) => propertyMutations.createTag(tag);
  Future<void> updateTag(Tag tag) => propertyMutations.updateTag(tag);
  Future<void> deleteTag(String tagKey) => propertyMutations.deleteTag(tagKey);

  // Global Templates Manager CRUD
  Future<List<Template>> getAllTemplates() =>
      templateMutations.getAllTemplates();
  Future<void> saveTemplateFromSelection(
    String name,
    List<String> nodeIds,
    List<String> relationIds,
  ) => templateMutations.saveTemplateFromSelection(name, nodeIds, relationIds);
  Future<void> instantiateTemplate(String key, Offset canvasCoords) =>
      templateMutations.instantiateTemplate(key, canvasCoords);
  Future<void> deleteTemplate(String key) =>
      templateMutations.deleteTemplate(key);

  Future<void> saveViewportState(ViewportState state) async {
    updateSavedViewportState(state);
    await syncEngine.api.updateViewportState(state: state);
  }

  Future<List<DatabaseSearchResult>> searchDatabase(String term) async {
    final rustNodes = await syncEngine.api.querySearch(query: term);
    final results = <DatabaseSearchResult>[];
    for (final rustNode in rustNodes) {
      if (rustNode is Nodes_INode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key,
            type: DatabaseSearchResultType.infoNode,
            text: node.content.text,
          ),
        );
      } else if (rustNode is Nodes_TaskNode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key,
            type: DatabaseSearchResultType.taskNode,
            text: node.content.text,
            state: node.state,
          ),
        );
      } else if (rustNode is Nodes_InterNode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key,
            type: DatabaseSearchResultType.relation,
            text: node.verb,
          ),
        );
      }
    }
    return results;
  }

  @override
  void addTagToNode(String nodeId, String name, int color) =>
      propertyMutations.addTagToNode(nodeId, name, color);

  @override
  void removeTagFromNode(String nodeId, String tagKey) =>
      propertyMutations.removeTagFromNode(nodeId, tagKey);

  @override
  void addCommentToNode(String nodeId, String text) =>
      propertyMutations.addCommentToNode(nodeId, text);

  @override
  void removeCommentFromNode(String nodeId, Comment comment) =>
      propertyMutations.removeCommentFromNode(nodeId, comment);

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  void dispose() {
    _log.fine('Disposing GraphDataController and dismantling domain modules.');
    _entityUpdateController.close();
    syncEngine.dispose();
    spatial.dispose();
  }
}
