import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:mycelium/shared/logging.dart';
import '../models/models.dart';
import '../presentation/view_state.dart';
import '../presentation/strategies/node_style_strategy.dart';
import 'interaction_context.dart';
import '../store/graph_data_query_controller.dart';
import '../store/command_queue_processor.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';
import '../presentation/node_render_state.dart';
import '../presentation/viewport_state.dart';
import '../presentation/workspace_tabs_controller.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

/// The Facade bridging the active FSM to the Data/UI Controllers.
class CanvasInteractionEnvironment implements InteractionContext {
  final Logger _log = Logger('CanvasInteractionEnvironment');
  final GraphDataQueryController _queryController;
  final CommandQueueProcessor _commandProcessor;
  final NodeRenderState _renderState;
  final ViewportController _viewportController;
  final double Function() _getScale;
  final TabSession? _boundSession;
  final void Function(List<String> nodeIds, List<String> relationIds)?
  _onSaveTemplate;

  CanvasInteractionEnvironment({
    required GraphDataQueryController queryController,
    required CommandQueueProcessor commandProcessor,
    required NodeRenderState renderState,
    required ViewportController viewportController,
    required double Function() getScale,
    TabSession? boundSession,
    void Function(List<String> nodeIds, List<String> relationIds)?
    onSaveTemplate,
  }) : _queryController = queryController,
       _commandProcessor = commandProcessor,
       _renderState = renderState,
       _viewportController = viewportController,
       _getScale = getScale,
       _boundSession = boundSession,
       _onSaveTemplate = onSaveTemplate;

  @override
  Map<String, NodeViewState> get nodeViewStates => _renderState.viewStates;

  @override
  RelationEngineState get relationEngine => _queryController.relationEngine;

  @override
  List<String> get zOrder => _renderState.zOrder;

  @override
  SpatialHashGrid get spatialGrid => _queryController.spatialGrid;

  @override
  Iterable<UiRelation> getRelations() => _queryController.relations;

  @override
  UiNode? getNode(RawUuid id) => _queryController.nodeLookup[id];

  @override
  void openDataInspector(RawUuid nodeId) {
    _log.info('openDataInspector nodeId=$nodeId');
    onSelectEntity(nodeId);
    _boundSession?.showRightPanel.value = true;
    _renderState.activeInspectorTabNotifier.value = InspectorTab.data;
  }

  @override
  void onNodeMove(RawUuid id, Offset pos) {
    _log.fine('onNodeMove id=$id');
    _commandProcessor.updateNodePosition(id, pos);
  }

  @override
  void onRelationCreate(
    RawUuid from,
    RawUuid to, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
    debugPrint('[InteractionFacade] onRelationCreate from=$from to=$to fromSide=$fromSide toSide=$toSide');
    _commandProcessor.createRelation(
      from,
      to,
      fromSide: fromSide,
      toSide: toSide,
      verb: verb,
    );
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
  void onCreateNode(Offset position) {
    _log.info('onCreateNode pos=(${position.dx}, ${position.dy})');
    // 1. Create the node via data layer
    final id = _commandProcessor.createNode(UiNodes.info, position);

    // 2. Open Data Inspector (which also selects and opens edit/inspector state)
    openDataInspector(id);
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
  Set<String> getSelectedEntities() => _renderState.selectedEntities;

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
  void setHoveredNodeMetadata(String? nodeId) {
    if (_renderState.hoveredNodeMetadataNotifier.value != nodeId) {
      _renderState.hoveredNodeMetadataNotifier.value = nodeId;
    }
  }

  @override
  void setHoveredNode(String? nodeId) {
    if (_renderState.hoveredNodeNotifier.value != nodeId) {
      _renderState.hoveredNodeNotifier.value = nodeId;
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
    _log.info('onCreateDrawingNode pos=(${position.dx}, ${position.dy}) type=$brushType');
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
}
