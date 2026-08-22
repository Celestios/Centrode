import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/in_memory_graph_api.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';
import 'package:centrode/features/graph/store/spatial_index.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Deterministic Virtual Time Gesture Test Harness for FSM Canvas interactions.
class GestureTestHarness {
  final FakeInteractionContext context;
  final TransformationController transformController;
  final InteractionController controller;

  Duration virtualTime = Duration.zero;
  int _pointerId = 1;

  GestureTestHarness({
    FakeInteractionContext? context,
  })  : context = context ?? FakeInteractionContext(),
        transformController = TransformationController(),
        controller = InteractionController(
          transformController: TransformationController(),
          environment: context ?? FakeInteractionContext(),
        );

  PointerDownEvent down(Offset pos, {int buttons = kPrimaryMouseButton}) {
    return PointerDownEvent(
      pointer: _pointerId,
      position: pos,
      buttons: buttons,
      timeStamp: virtualTime,
    );
  }

  PointerMoveEvent move(Offset pos, {int buttons = kPrimaryMouseButton}) {
    return PointerMoveEvent(
      pointer: _pointerId,
      position: pos,
      buttons: buttons,
      timeStamp: virtualTime,
    );
  }

  PointerUpEvent up(Offset pos) {
    final event = PointerUpEvent(
      pointer: _pointerId,
      position: pos,
      timeStamp: virtualTime,
    );
    _pointerId++;
    return event;
  }

  PointerCancelEvent cancel(Offset pos) {
    final event = PointerCancelEvent(
      pointer: _pointerId,
      position: pos,
      timeStamp: virtualTime,
    );
    _pointerId++;
    return event;
  }

  void advanceTime(Duration delta) {
    virtualTime += delta;
  }

  void dispose() {
    controller.dispose();
    transformController.dispose();
  }
}

/// In-memory fake of [InteractionContext] with stateful tracking.
class FakeInteractionContext implements InteractionContext {
  final Map<RawUuid, Offset> nodePositions = {};
  final Map<RawUuid, Size> nodeSizes = {};
  final Map<RawUuid, NodeViewState> _nodeViewStates = {};
  final Set<RawUuid> selectedEntities = {};
  final List<String> eventLog = [];

  String _toolMode = 'select';
  Rect? _optArea;
  Offset panDeltaTotal = Offset.zero;
  final RelationEngineState _relationEngine = RelationEngineState(api: InMemoryGraphApi());
  final SpatialHashGrid _spatialGrid = SpatialHashGrid();
  final HierarchicalSpatialIndex _spatialIndex = HierarchicalSpatialIndex();

  void seedNode(String idStr, Offset pos, Size size) {
    final id = RawUuid.fromString(idStr);
    nodePositions[id] = pos;
    nodeSizes[id] = size;
  }

  @override
  Size get viewportSize => const Size(1920, 1080);

  @override
  double get currentScale => 1.0;

  @override
  void updateScale(double newScale) {}

  @override
  Set<RawUuid> getVisibleNodeIds() => nodePositions.keys.toSet();

  @override
  String get toolMode => _toolMode;

  @override
  void setToolMode(String mode) => _toolMode = mode;

  @override
  Rect? get optArea => _optArea;

  @override
  void onSetOptArea(Rect? bounds, {bool commitToBackend = true}) {
    _optArea = bounds;
  }

  @override
  void panViewport(Offset deltaScreen) {
    panDeltaTotal += deltaScreen;
    eventLog.add('panViewport:$deltaScreen');
  }

  @override
  Offset screenToCanvas(Offset screenPos) => screenPos;

  @override
  ViewportScope get activeScope => const RootViewportScope();

  @override
  TabSession? get boundSession => null;

  @override
  void openContainer(ContainerUiNode node, {bool animate = true, void Function(double)? onProgress, VoidCallback? onComplete}) {}

  @override
  void closeContainer(ContainerUiNode node, {bool animate = true, void Function(double)? onProgress, VoidCallback? onComplete}) {}

  @override
  void onSelectEntity(RawUuid? id) {
    selectedEntities.clear();
    if (id != null) selectedEntities.add(id);
    eventLog.add('selectEntity:$id');
  }

  @override
  Set<RawUuid> getSelectedEntities() => Set.from(selectedEntities);

  @override
  void onSelectEntities(Iterable<RawUuid> ids) {
    selectedEntities..clear()..addAll(ids);
    eventLog.add('selectEntities:${ids.toList()}');
  }

  @override
  Offset getToolbarOffset() => Offset.zero;

  @override
  void setToolbarOffset(Offset offset) {}

  @override
  void onDeleteSelectedEntities() {
    eventLog.add('deleteSelected');
  }

  @override
  void onSaveTemplate() {}

  @override
  void openDataInspector(RawUuid nodeId) {}

  @override
  Offset? calculateToolbarAnchor(Iterable<RawUuid> selectedIds) => null;

  @override
  Map<RawUuid, NodeViewState> get nodeViewStates => _nodeViewStates;

  @override
  RelationEngineState get relationEngine => _relationEngine;

  @override
  List<RawUuid> get zOrder => nodePositions.keys.toList();

  @override
  SpatialHashGrid get spatialGrid => _spatialGrid;

  @override
  HierarchicalSpatialIndex get spatialIndex => _spatialIndex;

  @override
  Iterable<UiRelation> getRelations() => const [];

  @override
  UiRelation? getRelation(RawUuid id) => null;

  @override
  UiNode? getNode(RawUuid id) => null;

  @override
  RawUuid? get hoveredNodeId => null;

  @override
  void onNodeMove(RawUuid id, Offset pos) {
    nodePositions[id] = pos;
    eventLog.add('nodeMove:$id to $pos');
  }

  @override
  void reparentNode(RawUuid id, RawUuid? targetParentId, Offset targetPos) {}

  @override
  void onRelationCreate(RawUuid from, RawUuid to, {PortSide? fromSide, PortSide? toSide, String? verb}) {
    eventLog.add('relationCreate:$from->$to');
  }

  @override
  void onRelationUpdateLayout(RawUuid id, {RawUuid? fromNodeId, RawUuid? toNodeId, PortSide? fromSide, PortSide? toSide, String? strategyType}) {}

  @override
  void onRelationUpdateStyle(RawUuid id, RelationStyle newStyle) {}

  @override
  void onNodeDragUpdate() {}

  @override
  void onNodesDrag(List<(RawUuid, Offset)> updates) {
    for (final update in updates) {
      nodePositions[update.$1] = update.$2;
    }
  }

  @override
  void setNodeDragging(RawUuid id, bool dragging) {}

  @override
  void onCommitActiveEdit() {}

  @override
  RawUuid? getActiveEditId() => null;

  @override
  void onEnterEditMode(RawUuid id) {}

  @override
  RawUuid onCreateNode(Offset position) {
    final id = RawUuid.fromString('node-created-${nodePositions.length}');
    nodePositions[id] = position;
    return id;
  }

  @override
  RawUuid onCreateFrame(Offset position, Size size, {RawUuid? parentContainerId}) {
    return RawUuid.fromString('frame-1');
  }

  @override
  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) {}

  @override
  void toggleNodeExpansion(RawUuid id) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
