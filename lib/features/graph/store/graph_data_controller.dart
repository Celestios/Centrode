import 'dart:async';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'graph_data_query.dart';
import 'spatial_index.dart';
import '../models/models.dart';
import 'command_processor.dart';
import 'package:mycelium/src/rust/bridge/api.dart' as rust;
import 'package:mycelium/src/rust/domain/nodes.dart';

import 'modules/graph_store.dart';
import 'modules/graph_spatial.dart';
import 'modules/graph_sync_engine.dart';
import 'modules/graph_node_mutations.dart';
import 'modules/graph_relation_mutations.dart';
import 'modules/graph_property_mutations.dart';
import 'modules/graph_template_mutations.dart';

abstract class GraphStyleUpdater {
  void updateStyleForNode(String id);
  void updateStyleForRelation(String id);
}

/// High-level orchestrator utilizing Clean Class Composition.
///
/// This controller acts as the central coordinator (Facade) for the graph state:
/// - **GraphStore**: Encapsulates $O(1)$ in-memory storage.
/// - **GraphSpatial**: Manages viewport culling and reactive geometry.
/// - **GraphSyncEngine**: Handles FFI sync, DB stream, and hydration.
/// - **GraphNodeMutations**: Handles node mutations (create, delete, move, resize).
/// - **GraphRelationMutations**: Handles relation mutations (create).
/// - **GraphPropertyMutations**: Handles property mutations (text, styling).
class GraphDataController implements GraphDataQuery {
  final Logger _log = Logger('GraphDataController');

  // ===========================================================================
  // Domain Modules (Composition)
  // ===========================================================================

  late final GraphStore store;
  late final GraphSpatial spatial;
  late final GraphSyncEngine syncEngine;

  late final GraphNodeMutations nodeMutations;
  late final GraphRelationMutations relationMutations;
  late final GraphPropertyMutations propertyMutations;
  late final GraphTemplateMutations templateMutations;

  // Dependency Inversion Hooks
  Size Function(UiNode, {bool isEditing})? sizeCalculator;
  NodeStyle Function(UiNode)? styleResolver;
  GraphStyleUpdater? styleUpdater;

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

  Size calculateNodeSize(UiNode node, {bool isEditing = false}) {
    return sizeCalculator?.call(node, isEditing: isEditing) ?? node.size;
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
  GraphDataController(rust.AppHandle apiHandle) {
    store = GraphStore();
    spatial = GraphSpatial();
    syncEngine = GraphSyncEngine(
      controller: this,
      api: apiHandle,
      processor: CommandProcessor(
        onError: _handleError,
        onQueueDrained: updateHistoryStatus,
      ),
    );
    nodeMutations = GraphNodeMutations(this);
    relationMutations = GraphRelationMutations(this);
    propertyMutations = GraphPropertyMutations(this);
    templateMutations = GraphTemplateMutations(this);

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

  void triggerUpdate() {
    publishUpdate(
      GraphEntityUpdate(id: '', tableName: '', type: GraphUpdateType.reset),
    );
  }

  // ===========================================================================
  // Delegator Methods (Public API Contract)
  // ===========================================================================

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
  }) => nodeMutations.createNode(
    type,
    position,
    paths: paths,
    brushType: brushType,
    brushThickness: brushThickness,
    brushColor: brushColor,
    size: size,
  );

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

  void updateRelationStyle(String id, RelationStyle newStyle) =>
      propertyMutations.updateRelationStyle(id, newStyle);

  void updateRelationsLayout(
    List<String> ids, {
    String? strategyType,
  }) => relationMutations.updateRelationsLayout(ids, strategyType: strategyType);

  // Property Mutations
  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent}) =>
      propertyMutations.commitEntityText(
        id,
        newTextOrContent,
        originalTextOrContent: originalTextOrContent,
      );

  void updateEntityTextLive(String id, dynamic newTextOrContent) =>
      propertyMutations.updateEntityTextLive(id, newTextOrContent);

  void updateNodeStyle(String id, NodeStyle newStyle) =>
      propertyMutations.updateNodeStyle(id, newStyle);

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

  Future<List<UiSearchResult>> searchDatabase(String term) async {
    final rustNodes = await syncEngine.api.querySearch(query: term);
    final results = <UiSearchResult>[];
    for (final rustNode in rustNodes) {
      if (rustNode is Nodes_INode) {
        final node = rustNode.field0;
        results.add(
          UiSearchResult(
            key: node.id.key,
            title: node.content.text.isEmpty
                ? 'Untitled Node'
                : node.content.text,
            subtitle: 'Database • Info',
            type: UiSearchResultType.infoNode,
          ),
        );
      } else if (rustNode is Nodes_TaskNode) {
        final node = rustNode.field0;
        results.add(
          UiSearchResult(
            key: node.id.key,
            title: node.content.text.isEmpty
                ? 'Untitled Node'
                : node.content.text,
            subtitle: 'Database • Task • State: ${node.state}',
            type: UiSearchResultType.taskNode,
          ),
        );
      } else if (rustNode is Nodes_InterNode) {
        final node = rustNode.field0;
        results.add(
          UiSearchResult(
            key: node.id.key,
            title: node.verb.isEmpty ? 'Untitled Relation' : node.verb,
            subtitle: 'Database • Inter',
            type: UiSearchResultType.relation,
          ),
        );
      }
    }
    return results;
  }

  void addTagToNode(String nodeId, String name, int color) {
    final node = nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newTag = Tag(
        key: const Uuid().v4(),
        fields: TagFields(
          name: name,
          color: color,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      updateNodeTags(nodeId, [...node.tags, newTag]);
    }
  }

  void removeTagFromNode(String nodeId, String tagKey) {
    final node = nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedTags = node.tags.where((t) => t.key != tagKey).toList();
      updateNodeTags(nodeId, updatedTags);
    }
  }

  void addCommentToNode(String nodeId, String text) {
    final node = nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final newComment = Comment(
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      updateNodeComments(nodeId, [newComment, ...node.comments]);
    }
  }

  void removeCommentFromNode(String nodeId, Comment comment) {
    final node = nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedComments = node.comments.where((c) => c != comment).toList();
      updateNodeComments(nodeId, updatedComments);
    }
  }

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
