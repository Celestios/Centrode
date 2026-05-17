import 'dart:ui';
import '../models/models.dart';
import '../presentation/view_state.dart';
import 'interaction_context.dart';
import '../store/graph_repository.dart';
import '../state/graph_ui_controller.dart';

/// The Facade bridging the active FSM to the Data/UI Controllers.
class CanvasInteractionEnvironment implements InteractionContext {
  final GraphDataController _dataController;
  final GraphUIController _uiController;
  final double Function() _getScale;

  CanvasInteractionEnvironment({
    required GraphDataController dataController,
    required GraphUIController uiController,
    required double Function() getScale,
  }) : _dataController = dataController,
       _uiController = uiController,
       _getScale = getScale;

  @override
  Map<String, NodeViewState> get nodeViewStates =>
      _dataController.allNodeViewStates;

  @override
  List<String> get zOrder => _uiController.zOrder;

  @override
  Iterable<UiRelation> getRelations() => _dataController.relations;

  @override
  void onNodeMove(String id, Offset pos) =>
      _dataController.updateNodePosition(id, pos);

  @override
  void onRelationCreate(String from, String to) =>
      _dataController.createRelation(from, to);

  @override
  void onNodeDragUpdate() => _dataController.triggerUpdate();

  @override
  String? getActiveEditId() => _uiController.activeEditId;

  @override
  void onEnterEditMode(String id) => _uiController.enterEditMode(id);

  @override
  void onCommitActiveEdit() => _uiController.cancelActiveEdit();

  @override
  void onCreateNode(Offset position) {
    // 1. Create the node via data layer
    final id = _dataController.createNode(UiNodes.info, position);

    // 3. Trigger UI edit mode
    _uiController.enterEditMode(id);
  }

  @override
  void updateNodeWidth(double leftEdge, double rightEdge) {
    if (_uiController.selectedEntities.isNotEmpty) {
      final id = _uiController.selectedEntities.first;
      _dataController.updateNodeWidth(id, leftEdge, rightEdge);
    }
  }

  @override
  void onSelectEntity(String? id) => _uiController.selectEntity(id);

  @override
  void onSelectEntities(Iterable<String> ids) =>
      _uiController.selectEntities(ids);

  @override
  Set<String> getSelectedEntities() => _uiController.selectedEntities;

  @override
  Offset getToolbarOffset() => _uiController.toolbarOffsetNotifier.value;

  @override
  void updateToolbarOffset(Offset delta) {
    _uiController.toolbarOffsetNotifier.value += delta;
  }

  @override
  void onDeleteSelectedEntities() => _uiController.deleteSelectedEntities();

  @override
  Set<String> getVisibleNodeIds() => _uiController.visibleNodeIds.value;

  @override
  double get currentScale => _getScale();
}
