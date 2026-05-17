import 'dart:ui';
import '../models/models.dart';
import '../presentation/view_state.dart';
import 'interaction_context.dart';
import '../store/graph_repository.dart';
import '../presentation/node_render_state.dart';
import '../presentation/viewport_state.dart';

/// The Facade bridging the active FSM to the Data/UI Controllers.
class CanvasInteractionEnvironment implements InteractionContext {
  final GraphDataController _dataController;
  final NodeRenderState _renderState;
  final ViewportController _viewportController;
  final double Function() _getScale;

  CanvasInteractionEnvironment({
    required GraphDataController dataController,
    required NodeRenderState renderState,
    required ViewportController viewportController,
    required double Function() getScale,
  }) : _dataController = dataController,
       _renderState = renderState,
       _viewportController = viewportController,
       _getScale = getScale;

  @override
  Map<String, NodeViewState> get nodeViewStates => _renderState.viewStates;

  @override
  List<String> get zOrder => _renderState.zOrder;

  @override
  Iterable<UiRelation> getRelations() => _dataController.relations;

  @override
  void onNodeMove(String id, Offset pos) =>
      _dataController.updateNodePosition(id, pos);

  @override
  void onRelationCreate(String from, String to) =>
      _dataController.createRelation(from, to);

  @override
  void onNodeDragUpdate() => _renderState.notifyNodeDragUpdate();

  @override
  void setNodeDragging(String id, bool dragging) =>
      _renderState.setNodeDragging(id, dragging);

  @override
  String? getActiveEditId() => _renderState.activeEditId;

  @override
  void onEnterEditMode(String id) => _renderState.enterEditMode(id);

  @override
  void onCommitActiveEdit() => _renderState.cancelActiveEdit();

  @override
  void onCreateNode(Offset position) {
    // 1. Create the node via data layer
    final id = _dataController.createNode(UiNodes.info, position);

    // 2. Trigger UI edit mode
    _renderState.enterEditMode(id);
  }

  @override
  void updateNodeWidth(double leftEdge, double rightEdge) {
    if (_renderState.selectedEntities.isNotEmpty) {
      final id = _renderState.selectedEntities.first;
      _dataController.updateNodeWidth(id, leftEdge, rightEdge);
    }
  }

  @override
  void onSelectEntity(String? id) => _renderState.selectEntity(id);

  @override
  void onSelectEntities(Iterable<String> ids) =>
      _renderState.selectEntities(ids);

  @override
  Set<String> getSelectedEntities() => _renderState.selectedEntities;

  @override
  Offset getToolbarOffset() => _renderState.toolbarOffsetNotifier.value;

  @override
  void updateToolbarOffset(Offset delta) {
    _renderState.toolbarOffsetNotifier.value += delta;
  }

  @override
  void onDeleteSelectedEntities() => _renderState.deleteSelectedEntities();

  @override
  Set<String> getVisibleNodeIds() => _viewportController.visibleNodeIds.value;

  @override
  double get currentScale => _getScale();
}
