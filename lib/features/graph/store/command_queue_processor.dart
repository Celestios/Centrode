import 'dart:async';
import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import '../models/models.dart';
import 'graph_data_query_controller.dart';
import 'graph_data_query.dart';
import 'graph_data_command.dart';
import 'relation_engine_state.dart';
import 'modules/graph_store.dart';
import 'modules/graph_spatial.dart';
import 'modules/graph_sync_engine.dart';
import 'modules/graph_node_mutations.dart';
import 'modules/graph_relation_mutations.dart';
import 'modules/graph_property_mutations.dart';
import 'modules/graph_template_mutations.dart';
import 'command_processor.dart';
import '../models/commands/graph_command_context.dart';
import '../models/commands/patch_helpers.dart';
import 'graph_api.dart';

class CommandQueueProcessor implements GraphCommandContext, GraphDataCommand {
  final Logger _log = Logger('CommandQueueProcessor');

  final GraphDataQueryController queryController;
  final GraphApi api;

  late final GraphSyncEngine syncEngine;
  late final GraphNodeMutations nodeMutations;
  late final GraphRelationMutations relationMutations;
  late final GraphPropertyMutations propertyMutations;
  late final GraphTemplateMutations templateMutations;
  late final CommandProcessor processor;

  // Sizing & styling delegates
  ({Size size, int lineCount}) Function(UiNode, {bool isEditing})? sizeCalculator;
  NodeStyle Function(UiNode)? styleResolver;

  @override
  GraphStyleUpdater? styleUpdater;

  CommandQueueProcessor(
    this.api,
    this.queryController, {
    this.sizeCalculator,
    this.styleResolver,
    this.styleUpdater,
  }) {
    processor = CommandProcessor(
      onError: _handleError,
      onQueueDrained: updateHistoryStatus,
    );
    syncEngine = GraphSyncEngine(
      controller: this,
      api: api,
      processor: processor,
    );
    nodeMutations = GraphNodeMutations(this);
    relationMutations = GraphRelationMutations(this);
    propertyMutations = GraphPropertyMutations(this);
    templateMutations = GraphTemplateMutations(this);
  }

  // ===========================================================================
  // GraphCommandContext Implementation
  // ===========================================================================

  @override
  GraphStore get store => queryController.store;

  @override
  GraphSpatial get spatial => queryController.spatial;

  @override
  RelationEngineState get relationEngine => queryController.relationEngine;

  @override
  void publishUpdate(GraphEntityUpdate update) {
    queryController.publishUpdate(update);
  }

  @override
  void triggerUpdate() {
    queryController.triggerUpdate();
  }

  // ===========================================================================
  // Sizing & Styling delegates
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
      'styleResolver must be configured on CommandQueueProcessor before resolving styles for unstyled nodes.',
    );
  }

  // ===========================================================================
  // History & Error Handling
  // ===========================================================================

  int _undoCount = 0;
  int _redoCount = 0;

  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    queryController.errorMessage = msg;
    triggerUpdate();
  }

  void Function(String) get onError => _handleError;

  Future<void> updateHistoryStatus() async {
    try {
      _undoCount = await syncEngine.api.undoCount();
      _redoCount = await syncEngine.api.redoCount();
      triggerUpdate();
    } catch (e) {
      _log.warning('Failed to update history status: $e');
    }
  }

  ViewportState? getSavedViewportState() {
    return syncEngine.savedViewportState;
  }

  void updateSavedViewportState(ViewportState state) {
    syncEngine.updateSavedViewportState(state);
  }

  @override
  Future<void> loadGraph() async {
    queryController.isLoading = true;
    triggerUpdate();
    final stopwatch = Stopwatch()..start();
    _log.info('loadGraph: Initiating FFI request to load graph state.');

    try {
      await syncEngine.loadGraph();
      await updateHistoryStatus();

      relationEngine.onInitialLoad(
        relations: store.relations,
      );
      unawaited(relationEngine.recomputeDirty());

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
      queryController.isLoading = false;
      triggerUpdate();
    }
  }

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

  void updateNodePosition(String id, Offset newPosition) {
    nodeMutations.updateNodePosition(id, newPosition);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [(parseTypedRecordId(node.tableName, id), newPosition.dx, newPosition.dy, node.size.width, node.size.height)],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void updateNodePositionsVolatile(List<(String, Offset)> updates) {
    final List<(TypedRecordId, double, double, double, double)> positions = [];
    for (final update in updates) {
      final id = update.$1;
      final newPos = update.$2;
      final node = store.nodeLookup[id];
      if (node != null) {
        positions.add((
          parseTypedRecordId(node.tableName, id),
          newPos.dx,
          newPos.dy,
          node.size.width,
          node.size.height,
        ));
      }
    }
    if (positions.isNotEmpty) {
      syncEngine.api.updateNodeCachePositions(positions: positions);
      for (final update in updates) {
        relationEngine.onNodeMoved(update.$1);
      }
    }
  }

  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    nodeMutations.updateNodeWidth(id, leftEdge, rightEdge);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [(parseTypedRecordId(node.tableName, id), node.position.dx, node.position.dy, node.size.width, node.size.height)],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void toggleNodeExpansion(String id) {
    nodeMutations.toggleNodeExpansion(id);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [(parseTypedRecordId(node.tableName, id), node.position.dx, node.position.dy, node.size.width, node.size.height)],
      );
    }
    relationEngine.onNodeMoved(id);
  }

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
  Future<void> deleteRelation(String id) async {
    await relationMutations.deleteRelation(id);
    relationEngine.onRelationDeleted(id);
  }

  void updateRelationLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) {
    relationMutations.updateRelationLayout(
      id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      fromSide: fromSide,
      toSide: toSide,
      strategyType: strategyType,
    );
    relationEngine.onRelationLayoutUpdated(id);
  }

  void updateRelationStyle(String id, RelationStyle newStyle) {
    propertyMutations.updateRelationStyle(id, newStyle);
    relationEngine.onRelationLayoutUpdated(id);
  }

  @override
  void updateRelationsLayout(
    List<String> ids, {
    String? strategyType,
  }) {
    relationMutations.updateRelationsLayout(ids, strategyType: strategyType);
    for (final id in ids) {
      relationEngine.onRelationLayoutUpdated(id);
    }
  }

  @override
  void updateNodesStyle(List<String> ids, NodeStyle Function(NodeStyle style) updateFn) =>
      propertyMutations.updateNodesStyle(ids, updateFn);

  @override
  void addTagToNode(String nodeId, String name, int color) {
    propertyMutations.addTagToNode(nodeId, name, color);
  }

  @override
  void removeTagFromNode(String nodeId, String tagKey) {
    propertyMutations.removeTagFromNode(nodeId, tagKey);
  }

  @override
  void addCommentToNode(String nodeId, String text) {
    propertyMutations.addCommentToNode(nodeId, text);
  }

  @override
  void removeCommentFromNode(String nodeId, Comment comment) {
    propertyMutations.removeCommentFromNode(nodeId, comment);
  }

  @override
  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent}) {
    propertyMutations.commitEntityText(id, newTextOrContent, originalTextOrContent: originalTextOrContent);
  }

  @override
  void updateEntityTextLive(String id, dynamic newTextOrContent) {
    propertyMutations.updateEntityTextLive(id, newTextOrContent);
  }

  void dispose() {
    syncEngine.dispose();
  }
}
