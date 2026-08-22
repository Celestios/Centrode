import 'dart:async';
import 'dart:ui';
import 'package:centrode/shared/logging.dart';
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
import 'modules/graph_area_mutations.dart';
import 'command_processor.dart';
import '../models/commands/graph_command_context.dart';
import '../models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import 'graph_api.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class CommandQueueProcessor implements GraphCommandContext, GraphDataCommand {
  final Logger _log = Logger('CommandQueueProcessor');

  final GraphDataQueryController queryController;
  final GraphApi api;

  late final GraphSyncEngine syncEngine;
  late final GraphNodeMutations nodeMutations;
  late final GraphRelationMutations relationMutations;
  late final GraphPropertyMutations propertyMutations;
  late final GraphTemplateMutations templateMutations;
  late final GraphAreaMutations areaMutations;
  late final CommandProcessor processor;

  // Sizing & styling delegates
  ({Size size, int lineCount}) Function(UiNode, {bool isEditing})?
  sizeCalculator;
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
    areaMutations = GraphAreaMutations(this);
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

  ({Size size, int lineCount}) calculateNodeSize(
    UiNode node, {
    bool isEditing = false,
  }) {
    return sizeCalculator?.call(node, isEditing: isEditing) ??
        (size: node.size, lineCount: node.lineCount);
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
  bool _graphLoadInProgress = false;

  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  Future<void> flush() async {
    await processor.flush();
  }

  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    queryController.setError(msg);
    triggerUpdate();
  }

  void Function(String) get onError => _handleError;

  Future<void> updateHistoryStatus() async {
    _undoCount = await syncEngine.api.undoCount();
    _redoCount = await syncEngine.api.redoCount();
    triggerUpdate();
  }

  ViewportState? getSavedViewportState() {
    return syncEngine.savedViewportState;
  }

  void updateSavedViewportState(ViewportState state) {
    syncEngine.updateSavedViewportState(state);
  }

  @override
  Future<void> loadGraph() async {
    if (_graphLoadInProgress) {
      _log.info('loadGraph: Already in progress, skipping.');
      return;
    }
    _graphLoadInProgress = true;
    queryController.setLoading(true);
    triggerUpdate();
    _log.info('loadGraph: Initiating FFI request to load graph state.');

    try {
      await syncEngine.loadGraph();
      await updateHistoryStatus();

      relationEngine.onInitialLoad(relations: store.relations);
      unawaited(relationEngine.recomputeDirty());

      _log.info('loadGraph: Completed successfully.');
    } finally {
      queryController.setLoading(false);
      triggerUpdate();
      _graphLoadInProgress = false;
    }
  }

  void flushSync() => syncEngine.flushSync();

  Future<void> undo() async {
    await syncEngine.undo();
    await updateHistoryStatus();
  }

  Future<void> redo() async {
    await syncEngine.redo();
    await updateHistoryStatus();
  }

  @override
  RawUuid createNode(
    UiNodes type,
    Offset position, {
    RawUuid? parentContainerId,
    List<String>? paths,
    String? brushType,
    double? brushThickness,
    String? brushColor,
    Size? size,
    Content? content,
    Attachment? attachment,
    MediaType? mediaType,
  }) => nodeMutations.createNode(
    type,
    position,
    parentContainerId: parentContainerId,
    paths: paths,
    brushType: brushType,
    brushThickness: brushThickness,
    brushColor: brushColor,
    size: size,
    content: content,
    attachment: attachment,
    mediaType: mediaType,
  );

  @override
  Future<void> deleteNode(RawUuid id) => nodeMutations.deleteNode(id);

  @override
  void convertNodeToContainer(RawUuid id) {
    nodeMutations.convertNodeToContainer(id);
    relationEngine.onNodeMoved(id);
  }

  @override
  RawUuid createFrameFromSelection(Iterable<RawUuid> nodeIds, {Offset? defaultPosition}) {
    final frameId = nodeMutations.createFrameFromSelection(nodeIds, defaultPosition: defaultPosition);
    relationEngine.onNodeMoved(frameId);
    return frameId;
  }

  @override
  RawUuid? groupNodes(Iterable<RawUuid> nodeIds) {
    return nodeMutations.groupNodes(nodeIds);
  }

  @override
  void ungroupNodes(Iterable<RawUuid> nodeIds) {
    nodeMutations.ungroupNodes(nodeIds);
  }

  void updateNodePosition(RawUuid id, Offset newPosition) {
    nodeMutations.updateNodePosition(id, newPosition);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(node.tableName, id),
            newPosition.dx,
            newPosition.dy,
            node.size.width,
            node.size.height,
          ),
        ],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void reparentNode(RawUuid id, RawUuid? targetParentId, Offset targetPos) {
    nodeMutations.reparentNode(id, targetParentId, targetPos);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(node.tableName, id),
            targetPos.dx,
            targetPos.dy,
            node.size.width,
            node.size.height,
          ),
        ],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void updateNodePositionsVolatile(List<(RawUuid, Offset)> updates) {
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

  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) {
    nodeMutations.updateNodeWidth(id, leftEdge, rightEdge);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(node.tableName, id),
            node.position.dx,
            node.position.dy,
            node.size.width,
            node.size.height,
          ),
        ],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void toggleNodeExpansion(RawUuid id) {
    nodeMutations.toggleNodeExpansion(id);
    final node = store.nodeLookup[id];
    if (node != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(node.tableName, id),
            node.position.dx,
            node.position.dy,
            node.size.width,
            node.size.height,
          ),
        ],
      );
    }
    relationEngine.onNodeMoved(id);
  }

  void createRelation(
    RawUuid fromId,
    RawUuid toId, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
    final relation = relationMutations.createRelation(
      fromId,
      toId,
      fromSide: fromSide,
      toSide: toSide,
      verb: verb,
    );

    final fromNode = store.nodeLookup[fromId];
    final toNode = store.nodeLookup[toId];
    if (fromNode != null && toNode != null) {
      syncEngine.api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(fromNode.tableName, fromId),
            fromNode.position.dx,
            fromNode.position.dy,
            fromNode.size.width,
            fromNode.size.height,
          ),
          (
            parseTypedRecordId(toNode.tableName, toId),
            toNode.position.dx,
            toNode.position.dy,
            toNode.size.width,
            toNode.size.height,
          ),
        ],
      );
    }

    if (relation != null) {
      relationEngine.onRelationAdded(
        relation,
        fromNode: fromNode,
        toNode: toNode,
      );
    }
  }

  @override
  Future<void> deleteRelation(RawUuid id) async {
    await relationMutations.deleteRelation(id);
    relationEngine.onRelationDeleted(id);
  }

  void updateRelationLayout(
    RawUuid id, {
    RawUuid? fromNodeId,
    RawUuid? toNodeId,
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

  void updateRelationStyle(RawUuid id, RelationStyle newStyle) {
    propertyMutations.updateRelationStyle(id, newStyle);
    relationEngine.onRelationLayoutUpdated(id);
  }

  @override
  void updateRelationsLayout(List<RawUuid> ids, {String? strategyType}) {
    relationMutations.updateRelationsLayout(ids, strategyType: strategyType);
    for (final id in ids) {
      relationEngine.onRelationLayoutUpdated(id);
    }
  }

  @override
  void updateNodesStyle(
    List<RawUuid> ids,
    NodeStyle Function(NodeStyle style) updateFn,
  ) => propertyMutations.updateNodesStyle(ids, updateFn);

  @override
  void addTagToNode(RawUuid nodeId, String name, int color) {
    propertyMutations.addTagToNode(nodeId, name, color);
  }

  @override
  void removeTagFromNode(RawUuid nodeId, String tagKey) {
    propertyMutations.removeTagFromNode(nodeId, tagKey);
  }

  @override
  void addCommentToNode(RawUuid nodeId, String text) {
    propertyMutations.addCommentToNode(nodeId, text);
  }

  @override
  void removeCommentFromNode(RawUuid nodeId, Comment comment) {
    propertyMutations.removeCommentFromNode(nodeId, comment);
  }

  @override
  void commitEntityText(
    RawUuid id,
    dynamic newTextOrContent, {
    dynamic originalTextOrContent,
  }) {
    propertyMutations.commitEntityText(
      id,
      newTextOrContent,
      originalTextOrContent: originalTextOrContent,
    );
  }

  @override
  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent) {
    propertyMutations.updateEntityTextLive(id, newTextOrContent);
  }

  @override
  Future<void> createTag(Tag tag) => propertyMutations.createTag(tag);

  @override
  Future<void> updateTag(Tag tag) => propertyMutations.updateTag(tag);

  @override
  Future<void> deleteTag(String tagKey) => propertyMutations.deleteTag(tagKey);

  Future<void> triggerLayoutOptimization({
    LayoutConfig config = const LayoutConfig(
      force: ForceConfig(
        repulsionConstant: 8000.0,
        springConstant: 0.06,
        idealLinkDistance: 220.0,
        collisionStrength: 1.2,
        baseMargin: 35.0,
        marginScale: 0.2,
        wallStrength: 1.2,
        wallPadding: 20.0,
        damping: 0.35,
        alphaDecay: 0.006,
        alphaMin: 0.001,
        relationStretchFactor: 0.5,
        nodeEdgeRepulsion: 1500.0,
        densityDispersionStrength: 300.0,
      ),
      convergence: ConvergenceCriteria(
        maxIterations: 600,
        energyThreshold: 0.005,
        displacementThreshold: 0.2,
        oscillationWindow: 10,
      ),
      batchSize: 1,
    ),
    required List<LayoutPatch> livePositions,
  }) => areaMutations.triggerLayoutOptimization(
    config: config,
    livePositions: livePositions,
  );

  Future<void> setOptArea({BoundingBox? bounds}) =>
      areaMutations.setOptArea(bounds: bounds);

  void dispose() {
    processor.dispose();
    syncEngine.dispose();
  }
}
