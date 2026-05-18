import 'dart:async';
import 'dart:ui';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import '../graph_data_controller.dart';
import '../../presentation/strategies/node_layout_strategy.dart';


/// Node mutation operations for the graph.
class GraphNodeMutations {
  final Logger _nodeLog = Logger('GraphNodeMutations');
  final GraphDataController controller;

  GraphNodeMutations(this.controller);

  /// Creates a node with immediate UI injection (T=0.0ms pattern).
  String createNode(UiNodes type, Offset position) {
    _nodeLog.fine("Creating node...");
    UiNode node;
    switch (type) {
      case UiNodes.info:
        node = InfoUiNode(position: position);
        break;
      case UiNodes.task:
        node = TaskUiNode(position: position);
    }
    String id = node.id;
    controller.store.nodeLookup[id] = node;
    controller.spatial.spatialGrid.insert(id, position);
    controller.spatial.saveConfirmedPosition(id, position);

    // Resolve the node style immediately so it doesn't render with a transparent/stale fallback style
    controller.styleManager.updateStyleForNode(id);

    // Compute the correct initial size based on the layout strategy and resolved style
    final strategy = node is InfoUiNode
        ? const InfoNodeLayoutStrategy()
        : const TaskNodeLayoutStrategy();
    node.size = strategy.calculate(node, node.resolvedStyle);


    final cmd = CreateNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      node: node,
      onUndo: () {
        _nodeLog.warning('Creation rejected or failed. Removing node: $id');
        controller.store.nodeLookup.remove(id);
        controller.spatial.spatialGrid.remove(id, position);
        controller.spatial.clearConfirmedPosition(id);
        controller.triggerUpdate();
      },
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    controller.triggerUpdate();
    return id;
  }

  /// Deletes a node with immediate command execution via CommandProcessor.
  /// Handles deletion race condition by ensuring delete executes before any pending moves.
  Future<void> deleteNode(String id) async {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    _nodeLog.info('Initiating optimistic UI teardown for node: $id');

    // Prepare Command for FFI with rollback
    final cmd = DeleteNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      tableName: node.tableName, // Use canonical name instead of hardcoded string
      onUndo: () {
        _nodeLog.warning('Deletion rejected. Re-hydrating node: $id');
        controller.store.nodeLookup[id] = node;
        controller.spatial.spatialGrid.insert(id, node.position);
        controller.triggerUpdate(); // Force canvas rebuild to re-mount the rehydrated node
      },
    );

    // OPTIMISTIC TEARDOWN
    controller.store.nodeLookup.remove(id);
    controller.spatial.spatialGrid.remove(id, node.position);
    controller.spatial.clearConfirmedPosition(id);

    // Queue command with immediate execution
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.triggerUpdate();
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Tracks the last confirmed DB position to prevent "Superseded Rollback Traps".
  void updateNodePosition(String id, Offset newPosition) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    // Track the LAST confirmed position if this is a new sequence of moves
    final confirmedPos = controller.spatial.getConfirmedPosition(id) ?? node.position;
    controller.spatial.saveConfirmedPosition(id, confirmedPos);

    final oldPosition = node.position;
    controller.spatial.spatialGrid.update(id, node.position, newPosition);
    node.position = newPosition;

    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: controller.syncEngine.api,
      onSuccess: () => controller.spatial.saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        controller.spatial.spatialGrid.update(id, newPosition, oldPosition);
        controller.triggerUpdate();
      },
    );

    // Queue command with debouncing (300ms delay)
    controller.syncEngine.processor.queueCommand(cmd);
    controller.triggerUpdate();
  }

  /// Updates node width based on left and right edges.
  /// Calculates width and updates position if the left edge moved.
  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldPosition = node.position;
    final oldSize = node.size;

    final newWidth = rightEdge - leftEdge;
    final newPosition = Offset(leftEdge, node.position.dy);

    _nodeLog.fine(
      'UPDATING WIDTH: $id edges [$leftEdge, $rightEdge] -> width $newWidth',
    );

    node.position = newPosition;
    node.size = Size(newWidth, node.size.height);

    controller.spatial.spatialGrid.update(id, oldPosition, newPosition);

    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: controller.syncEngine.api,
      onSuccess: () => controller.spatial.saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        node.size = oldSize;
        controller.spatial.spatialGrid.update(id, newPosition, oldPosition);
        controller.triggerUpdate();
      },
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.triggerUpdate();
  }
}
