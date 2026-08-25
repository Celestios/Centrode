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
import 'handlers/handlers.dart';
import 'command_processor.dart';
import '../models/commands/graph_command_context.dart';
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import 'graph_api.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Central coordinator for graph command execution, queueing, and synchronization.
class CommandQueueProcessor implements GraphCommandContext, GraphDataCommand {
  final Logger _log = Logger('CommandQueueProcessor');

  final GraphDataQueryController queryController;
  final GraphApi api;

  late final CommandProcessor processor;
  late final GraphSyncEngine syncEngine;
  late final NodeCommandHandler nodeHandler;
  late final RelationCommandHandler relationHandler;
  late final PropertyCommandHandler propertyHandler;
  late final TemplateCommandHandler templateHandler;
  late final AreaCommandHandler areaHandler;
  late final HistoryCommandHandler historyHandler;

  // Compatibility getters for mutation modules
  GraphNodeMutations get nodeMutations => nodeHandler.mutations;
  GraphRelationMutations get relationMutations => relationHandler.mutations;
  PropertyCommandHandler get propertyMutations => propertyHandler;
  TemplateCommandHandler get templateMutations => templateHandler;
  AreaCommandHandler get areaMutations => areaHandler;

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
    nodeHandler = NodeCommandHandler(
      context: this,
      api: api,
      processor: processor,
    );
    relationHandler = RelationCommandHandler(
      context: this,
      api: api,
      processor: processor,
    );
    propertyHandler = PropertyCommandHandler(this);
    templateHandler = TemplateCommandHandler(
      api: api,
      context: this,
      processor: processor,
    );
    areaHandler = AreaCommandHandler(api: api);
    historyHandler = HistoryCommandHandler(
      api: api,
      processor: processor,
      onHistoryUpdated: triggerUpdate,
    );
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
  // History & Lifecycle
  // ===========================================================================

  int get undoCount => historyHandler.undoCount;
  int get redoCount => historyHandler.redoCount;
  bool get canUndo => historyHandler.canUndo;
  bool get canRedo => historyHandler.canRedo;

  bool _graphLoadInProgress = false;

  Future<void> flush() async {
    await processor.flush();
  }

  void flushSync() => syncEngine.flushSync();

  Future<void> updateHistoryStatus() async {
    await historyHandler.updateHistoryStatus();
  }

  Future<void> undo() async {
    await historyHandler.undo();
  }

  Future<void> redo() async {
    await historyHandler.redo();
  }

  void _handleError(String msg) {
    _log.severe('Sub-service error intercepted: $msg');
    queryController.setError(msg);
    triggerUpdate();
  }

  void Function(String) get onError => _handleError;

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

  // ===========================================================================
  // GraphDataCommand & Handler Delegations
  // ===========================================================================

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
  }) => nodeHandler.createNode(
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
  Future<void> deleteNode(RawUuid id) => nodeHandler.deleteNode(id);

  @override
  void convertNodeToContainer(RawUuid id) => nodeHandler.convertNodeToContainer(id);

  @override
  RawUuid createFrameFromSelection(Iterable<RawUuid> nodeIds, {Offset? defaultPosition}) =>
      nodeHandler.createFrameFromSelection(nodeIds, defaultPosition: defaultPosition);

  @override
  RawUuid? groupNodes(Iterable<RawUuid> nodeIds) => nodeHandler.groupNodes(nodeIds);

  @override
  void ungroupNodes(Iterable<RawUuid> nodeIds) => nodeHandler.ungroupNodes(nodeIds);

  void updateNodePosition(RawUuid id, Offset newPosition) =>
      nodeHandler.updateNodePosition(id, newPosition);

  void reparentNode(RawUuid id, RawUuid? targetParentId, Offset targetPos) =>
      nodeHandler.reparentNode(id, targetParentId, targetPos);

  void updateNodePositionsVolatile(List<(RawUuid, Offset)> updates) =>
      nodeHandler.updateNodePositionsVolatile(updates);

  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) =>
      nodeHandler.updateNodeWidth(id, leftEdge, rightEdge);

  void toggleNodeExpansion(RawUuid id) =>
      nodeHandler.toggleNodeExpansion(id);

  UiRelation? createRelation(
    RawUuid fromId,
    RawUuid toId, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) => relationHandler.createRelation(
    fromId,
    toId,
    fromSide: fromSide,
    toSide: toSide,
    verb: verb,
  );

  @override
  Future<void> deleteRelation(RawUuid id) => relationHandler.deleteRelation(id);

  void updateRelationLayout(
    RawUuid id, {
    RawUuid? fromNodeId,
    RawUuid? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) => relationHandler.updateRelationLayout(
    id,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    fromSide: fromSide,
    toSide: toSide,
    strategyType: strategyType,
  );

  void updateRelationStyle(RawUuid id, RelationStyle newStyle) =>
      propertyHandler.updateRelationStyle(id, newStyle);

  @override
  void updateRelationsLayout(List<RawUuid> ids, {String? strategyType}) =>
      relationHandler.updateRelationsLayout(ids, strategyType: strategyType);

  @override
  void updateNodesStyle(
    List<RawUuid> ids,
    NodeStyle Function(NodeStyle style) updateFn,
  ) => propertyHandler.updateNodesStyle(ids, updateFn);

  @override
  void addTagToNode(RawUuid nodeId, String name, int color) =>
      propertyHandler.addTagToNode(nodeId, name, color);

  @override
  void removeTagFromNode(RawUuid nodeId, String tagKey) =>
      propertyHandler.removeTagFromNode(nodeId, tagKey);

  @override
  void addCommentToNode(RawUuid nodeId, String text) =>
      propertyHandler.addCommentToNode(nodeId, text);

  @override
  void removeCommentFromNode(RawUuid nodeId, Comment comment) =>
      propertyHandler.removeCommentFromNode(nodeId, comment);

  @override
  void commitEntityText(
    RawUuid id,
    dynamic newTextOrContent, {
    dynamic originalTextOrContent,
  }) => propertyHandler.commitEntityText(
    id,
    newTextOrContent,
    originalTextOrContent: originalTextOrContent,
  );

  @override
  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent) =>
      propertyHandler.updateEntityTextLive(id, newTextOrContent);

  @override
  Future<void> createTag(Tag tag) => propertyHandler.createTag(tag);

  @override
  Future<void> updateTag(Tag tag) => propertyHandler.updateTag(tag);

  @override
  Future<void> deleteTag(String tagKey) => propertyHandler.deleteTag(tagKey);

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
  }) => areaHandler.triggerLayoutOptimization(
    config: config,
    livePositions: livePositions,
  );

  Future<void> setOptArea({BoundingBox? bounds}) =>
    areaHandler.setOptArea(bounds: bounds);

  void dispose() {
    processor.dispose();
    syncEngine.dispose();
  }
}
