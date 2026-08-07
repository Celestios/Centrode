import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:centrode/shared/logging.dart';
import '../models/models.dart';
import '../models/port.dart';
import '../presentation/view_state.dart';
import '../presentation/strategies/node_style_strategy.dart';
import '../presentation/handlers/spatial_action_handler.dart';
import '../presentation/handlers/topology_action_handler.dart';
import '../presentation/handlers/content_action_handler.dart';
import 'interaction_context.dart';
import '../store/graph_data_query_controller.dart';
import '../store/command_queue_processor.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';
import '../presentation/node_render_state.dart';
import '../presentation/viewport_state.dart';
import '../presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import '../models/commands/patch_helpers.dart';

/// The Facade bridging the active FSM to the Data/UI Controllers.
class CanvasInteractionEnvironment implements InteractionContext {
  final Logger _log = Logger('CanvasInteractionEnvironment');
  final GraphDataQueryController _queryController;
  final CommandQueueProcessor _commandProcessor;
  final NodeRenderState _renderState;
  final ViewportController _viewportController;
  final double Function() _getScale;
  final TabSession? _boundSession;
  final void Function(List<RawUuid> nodeIds, List<RawUuid> relationIds)?
  _onSaveTemplate;

  @override
  final SpatialActionHandler spatialHandler;
  @override
  final TopologyActionHandler topologyHandler;
  @override
  final ContentActionHandler contentHandler;

  CanvasInteractionEnvironment({
    required GraphDataQueryController queryController,
    required CommandQueueProcessor commandProcessor,
    required NodeRenderState renderState,
    required ViewportController viewportController,
    required double Function() getScale,
    TabSession? boundSession,
    void Function(List<RawUuid> nodeIds, List<RawUuid> relationIds)?
    onSaveTemplate,
    SpatialActionHandler? spatialHandler,
    TopologyActionHandler? topologyHandler,
    ContentActionHandler? contentHandler,
  }) : _queryController = queryController,
       _commandProcessor = commandProcessor,
       _renderState = renderState,
       _viewportController = viewportController,
       _getScale = getScale,
       _boundSession = boundSession,
       _onSaveTemplate = onSaveTemplate,
       spatialHandler = spatialHandler ?? const DefaultSpatialActionHandler(),
       topologyHandler =
           topologyHandler ?? const DefaultTopologyActionHandler(),
       contentHandler = contentHandler ?? const DefaultContentActionHandler();

  @override
  String get toolMode => _boundSession?.toolModeNotifier.value ?? 'select';

  @override
  void setToolMode(String mode) {
    _boundSession?.setToolMode(mode);
  }

  @override
  Map<RawUuid, NodeViewState> get nodeViewStates => _renderState.viewStates;

  @override
  RelationEngineState get relationEngine => _queryController.relationEngine;

  @override
  List<RawUuid> get zOrder => _renderState.zOrder;

  @override
  SpatialHashGrid get spatialGrid => _queryController.spatialGrid;

  @override
  Iterable<UiRelation> getRelations() => _queryController.relations;

  @override
  UiRelation? getRelation(RawUuid id) => _queryController.relationLookup[id];

  @override
  UiNode? getNode(RawUuid id) => _queryController.nodeLookup[id];

  @override
  RawUuid? get hoveredNodeId => _renderState.hoveredNodeNotifier.value;

  @override
  void openDataInspector(RawUuid nodeId) {
    _log.info('openDataInspector nodeId=$nodeId');
    onSelectEntity(nodeId);
    _renderState.activeInspectorTabNotifier.value = InspectorTab.data;
  }

  @override
  void onNodeMove(RawUuid id, Offset pos) {
    _log.fine('onNodeMove id=$id');
    _commandProcessor.updateNodePosition(id, pos);
    _triggerOptAreaLayoutIfActive(pos);
  }

  @override
  void onRelationCreate(
    RawUuid from,
    RawUuid to, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
    debugPrint(
      '[InteractionFacade] onRelationCreate from=$from to=$to fromSide=$fromSide toSide=$toSide',
    );
    _commandProcessor.createRelation(
      from,
      to,
      fromSide: fromSide,
      toSide: toSide,
      verb: verb,
    );
    final fromNode = _queryController.nodeLookup[from];
    final toNode = _queryController.nodeLookup[to];
    _triggerOptAreaLayoutIfActive(fromNode?.position ?? toNode?.position);
  }

  @override
  void onRelationUpdateLayout(
    RawUuid id, {
    RawUuid? fromNodeId,
    RawUuid? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) {
    _commandProcessor.updateRelationLayout(
      id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      fromSide: fromSide,
      toSide: toSide,
      strategyType: strategyType,
    );
    _triggerOptAreaLayoutIfActive();
  }

  @override
  void onRelationUpdateStyle(RawUuid id, RelationStyle newStyle) {
    _commandProcessor.updateRelationStyle(id, newStyle);
  }

  @override
  void onNodeDragUpdate() => _renderState.notifyNodeDragUpdate();

  @override
  void onNodesDrag(List<(RawUuid, Offset)> updates) {
    _commandProcessor.updateNodePositionsVolatile(updates);
    _renderState.notifyNodeDragUpdate();
  }

  @override
  void setNodeDragging(RawUuid id, bool dragging) =>
      _renderState.setNodeDragging(id, dragging);

  @override
  RawUuid? getActiveEditId() => _renderState.activeEditId;

  @override
  void onEnterEditMode(RawUuid id) {
    _log.info('onEnterEditMode id=$id');
    _renderState.enterEditMode(id);
    openDataInspector(id);
  }

  @override
  void onCommitActiveEdit() => _renderState.commitActiveEdit();

  @override
  RawUuid onCreateNode(Offset position) {
    _log.info('onCreateNode pos=(${position.dx}, ${position.dy})');
    // 1. Create the node via data layer
    final id = _commandProcessor.createNode(UiNodes.info, position);

    // 2. Open Data Inspector and activate edit mode
    openDataInspector(id);
    onEnterEditMode(id);

    // 3. Trigger OptArea layout optimization if inside bounds
    _triggerOptAreaLayoutIfActive(position);
    return id;
  }

  @override
  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) {
    _commandProcessor.updateNodeWidth(id, leftEdge, rightEdge);
  }

  @override
  void toggleNodeExpansion(RawUuid id) {
    _log.fine('toggleNodeExpansion id=$id');
    _commandProcessor.toggleNodeExpansion(id);
  }

  @override
  void onSelectEntity(RawUuid? id) => _renderState.selectEntity(id);

  @override
  void onSelectEntities(Iterable<RawUuid> ids) =>
      _renderState.selectEntities(ids);

  @override
  Set<RawUuid> getSelectedEntities() => _renderState.selectedEntities;

  @override
  Offset getToolbarOffset() {
    final isMulti = _renderState.selectedEntities.length > 1;
    return isMulti
        ? _renderState.multiToolbarOffsetNotifier.value
        : _renderState.toolbarOffsetNotifier.value;
  }

  @override
  void setToolbarOffset(Offset offset) {
    final isMulti = _renderState.selectedEntities.length > 1;
    if (isMulti) {
      _renderState.multiToolbarOffsetNotifier.value = offset;
    } else {
      _renderState.toolbarOffsetNotifier.value = offset;
    }
  }

  @override
  void onDeleteSelectedEntities() {
    _log.info('onDeleteSelectedEntities');
    _renderState.deleteSelectedEntities();
    _triggerOptAreaLayoutIfActive();
  }

  @override
  void onSaveTemplate() {
    final nodeIds = _renderState.selectedEntities
        .where((id) => _queryController.nodeLookup.containsKey(id))
        .toList();
    _log.info('onSaveTemplate nodes=${nodeIds.length}');
    if (nodeIds.isEmpty) return;

    final nodeIdsSet = nodeIds.toSet();
    final relationIds = _queryController.relationLookup.values
        .where(
          (r) =>
              (nodeIdsSet.contains(r.fromNodeId) &&
                  nodeIdsSet.contains(r.toNodeId)) ||
              _renderState.selectedEntities.contains(r.id),
        )
        .map((r) => r.id)
        .toList();

    _onSaveTemplate?.call(nodeIds, relationIds);
  }

  @override
  Set<RawUuid> getVisibleNodeIds() => _viewportController.visibleNodeIds.value;

  @override
  double get currentScale => _getScale();

  @override
  void updateNodeStyle(
    RawUuid id,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    final node = _queryController.nodeLookup[id];
    if (node != null) {
      final style = node.style ?? NodeStyleStrategy.resolveStyle(node);
      _commandProcessor.propertyMutations.updateNodeStyle(id, updateFn(style));
    }
  }

  @override
  Offset? calculateToolbarAnchor(Iterable<RawUuid> selectedIds) =>
      _renderState.calculateToolbarAnchor(selectedIds);

  @override
  void setHoveredNodeMetadata(RawUuid? nodeId) {
    if (_renderState.hoveredNodeMetadataNotifier.value != nodeId) {
      _renderState.hoveredNodeMetadataNotifier.value = nodeId;
    }
  }

  @override
  void setHoveredNode(RawUuid? nodeId) {
    if (_renderState.hoveredNodeNotifier.value != nodeId) {
      _renderState.hoveredNodeNotifier.value = nodeId;
    }
  }

  @override
  void setHoveredPort(Port? port) {
    if (_renderState.hoveredPortNotifier.value != port) {
      _renderState.hoveredPortNotifier.value = port;
    }
  }

  @override
  void onCreateDrawingNode({
    required Offset position,
    required List<String> paths,
    required String brushType,
    required double brushThickness,
    required String brushColor,
    required Size size,
  }) {
    _log.info(
      'onCreateDrawingNode pos=(${position.dx}, ${position.dy}) type=$brushType',
    );
    _commandProcessor.createNode(
      UiNodes.drawing,
      position,
      paths: paths,
      brushType: brushType,
      brushThickness: brushThickness,
      brushColor: brushColor,
      size: size,
    );
  }

  @override
  void onRelationSnapPreview({
    required RawUuid relationId,
    required bool isStartTip,
    required RawUuid targetNodeId,
    required String targetNodeTable,
    required PortSide? targetSide,
    required Offset overridePosition,
    PortSide? sourceSide,
  }) {
    final rel = _queryController.relationLookup[relationId];
    if (rel != null) {
      _queryController.relationEngine.computeRelationPreview(
        previewId: relationId,
        fromNodeId: isStartTip ? targetNodeId : rel.fromNodeId,
        toNodeId: isStartTip ? rel.toNodeId : targetNodeId,
        fromNodeTable: isStartTip ? targetNodeTable : rel.fromNodeTable,
        toNodeTable: isStartTip ? rel.toNodeTable : targetNodeTable,
        fromSide: isStartTip
            ? targetSide
            : (sourceSide ??
                  rel.resolvedLayout?.fromSide ??
                  rel.layout?.fromSide),
        toSide: isStartTip
            ? (rel.resolvedLayout?.toSide ?? rel.layout?.toSide)
            : targetSide,
      );
    } else {
      final sourceNode = getNode(relationId);
      if (sourceNode != null) {
        _queryController.relationEngine.computeRelationPreview(
          previewId: relationId,
          fromNodeId: relationId,
          toNodeId: targetNodeId,
          fromNodeTable: sourceNode.tableName,
          toNodeTable: targetNodeTable,
          fromSide: sourceSide,
          toSide: targetSide,
        );
      }
    }
  }

  @override
  Rect? get optArea => _queryController.optAreaNotifier.value;

  @override
  void onRelationSnapPreviewClear(RawUuid relationId) {
    _queryController.relationEngine.clearRelationPreview(relationId);
  }

  void _triggerOptAreaLayoutIfActive([Offset? testPoint]) async {
    final area = _queryController.optAreaNotifier.value;
    if (area == null) return;
    if (testPoint != null && !area.contains(testPoint)) return;

    _log.info('Triggering event-driven layout optimization pass for OptArea');
    await _commandProcessor.flush();

    final livePatches = _queryController.nodeLookup.values.map((node) {
      return LayoutPatch(
        id: parseTypedRecordId(node.tableName, node.id),
        x: node.position.dx,
        y: node.position.dy,
      );
    }).toList();

    _commandProcessor.api.triggerLayoutOptimization(
      config: const LayoutConfig(
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
      livePositions: livePatches,
    );
  }

  @override
  void onSetOptArea(Rect? bounds, {bool commitToBackend = true}) async {
    final boundingBox = bounds == null
        ? null
        : BoundingBox(
            minX: bounds.left,
            minY: bounds.top,
            maxX: bounds.right,
            maxY: bounds.bottom,
          );
    _log.info('Setting OptArea: $boundingBox (commitToBackend: $commitToBackend)');
    _queryController.optAreaNotifier.value = bounds;
    if (commitToBackend) {
      await _commandProcessor.api.setOptArea(bounds: boundingBox);
      if (boundingBox != null) {
        _triggerOptAreaLayoutIfActive();
      }
    }
  }
}
