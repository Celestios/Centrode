import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:mycelium/shared/logging.dart';
import '../models/models.dart';
import '../presentation/view_state.dart';
import '../presentation/strategies/node_style_strategy.dart';
import 'interaction_context.dart';
import '../store/graph_data_controller.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';
import '../presentation/node_render_state.dart';
import '../presentation/viewport_state.dart';
import '../presentation/workspace_tabs_controller.dart';

/// The Facade bridging the active FSM to the Data/UI Controllers.
class CanvasInteractionEnvironment implements InteractionContext {
  final Logger _log = Logger('CanvasInteractionEnvironment');
  final GraphDataController _dataController;
  final NodeRenderState _renderState;
  final ViewportController _viewportController;
  final double Function() _getScale;
  final TabSession? _boundSession;
  final void Function(List<String> nodeIds, List<String> relationIds)?
  _onSaveTemplate;

  CanvasInteractionEnvironment({
    required GraphDataController dataController,
    required NodeRenderState renderState,
    required ViewportController viewportController,
    required double Function() getScale,
    TabSession? boundSession,
    void Function(List<String> nodeIds, List<String> relationIds)?
    onSaveTemplate,
  }) : _dataController = dataController,
       _renderState = renderState,
       _viewportController = viewportController,
       _getScale = getScale,
       _boundSession = boundSession,
       _onSaveTemplate = onSaveTemplate;

  @override
  Map<String, NodeViewState> get nodeViewStates => _renderState.viewStates;

  @override
  RelationEngineState get relationEngine => _dataController.relationEngine;

  @override
  List<String> get zOrder => _renderState.zOrder;

  @override
  SpatialHashGrid get spatialGrid => _dataController.spatialGrid;

  @override
  Iterable<UiRelation> getRelations() => _dataController.relations;

  @override
  UiNode? getNode(String id) => _dataController.nodeLookup[id];

  @override
  void openDataInspector(String nodeId) {
    _log.info('openDataInspector nodeId=$nodeId');
    onSelectEntity(nodeId);
    _boundSession?.showRightPanel.value = true;
    _renderState.activeInspectorTabNotifier.value = InspectorTab.data;
  }

  @override
  void onNodeMove(String id, Offset pos) {
    _log.fine('onNodeMove id=$id');
    _dataController.updateNodePosition(id, pos);
  }

  @override
  void onRelationCreate(
    String from,
    String to, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
    debugPrint('[InteractionFacade] onRelationCreate from=$from to=$to fromSide=$fromSide toSide=$toSide');
    _dataController.createRelation(
      from,
      to,
      fromSide: fromSide,
      toSide: toSide,
      verb: verb,
    );
  }

  @override
  void onRelationUpdateLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) {
    _dataController.updateRelationLayout(
      id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      fromSide: fromSide,
      toSide: toSide,
      strategyType: strategyType,
    );
  }

  @override
  void onRelationUpdateStyle(String id, RelationStyle newStyle) {
    _dataController.updateRelationStyle(id, newStyle);
  }

  @override
  void onNodeDragUpdate() => _renderState.notifyNodeDragUpdate();

  @override
  void onNodesDrag(List<(String, Offset)> updates) {
    _dataController.updateNodePositionsVolatile(updates);
    _renderState.notifyNodeDragUpdate();
  }

  @override
  void setNodeDragging(String id, bool dragging) =>
      _renderState.setNodeDragging(id, dragging);

  @override
  String? getActiveEditId() => _renderState.activeEditId;

  @override
  void onEnterEditMode(String id) {
    _log.info('onEnterEditMode id=$id');
    _renderState.enterEditMode(id);
    openDataInspector(id);
  }

  @override
  void onCommitActiveEdit() => _renderState.cancelActiveEdit();

  @override
  void onCreateNode(Offset position) {
    _log.info('onCreateNode pos=(${position.dx}, ${position.dy})');
    // 1. Create the node via data layer
    final id = _dataController.createNode(UiNodes.info, position);

    // 2. Open Data Inspector (which also selects and opens edit/inspector state)
    openDataInspector(id);
  }

  @override
  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    _dataController.updateNodeWidth(id, leftEdge, rightEdge);
  }

  @override
  void toggleNodeExpansion(String id) {
    _log.fine('toggleNodeExpansion id=$id');
    _dataController.toggleNodeExpansion(id);
  }

  @override
  void onSelectEntity(String? id) => _renderState.selectEntity(id);

  @override
  void onSelectEntities(Iterable<String> ids) =>
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
        .where((id) => _dataController.nodeLookup.containsKey(id))
        .toList();
    _log.info('onSaveTemplate nodes=${nodeIds.length}');
    if (nodeIds.isEmpty) return;

    final nodeIdsSet = nodeIds.toSet();
    final relationIds = _dataController.relationLookup.values
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
  Set<String> getVisibleNodeIds() => _viewportController.visibleNodeIds.value;

  @override
  double get currentScale => _getScale();

  @override
  void updateNodeStyle(
    String id,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    final node = _dataController.nodeLookup[id];
    if (node != null) {
      final style = node.style ?? NodeStyleStrategy.resolveStyle(node);
      _dataController.updateNodeStyle(id, updateFn(style));
    }
  }

  @override
  Offset? calculateToolbarAnchor(Iterable<String> selectedIds) =>
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
    _dataController.createNode(
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
