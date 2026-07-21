import 'dart:async';
import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import '../../models/models.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';

/// Node mutation operations for the graph.
class GraphNodeMutations {
  final Logger _nodeLog = Logger('GraphNodeMutations');
  final CommandQueueProcessor controller;

  GraphNodeMutations(this.controller);

  /// Creates a node with immediate UI injection (T=0.0ms pattern).
  String createNode(
    UiNodes type,
    Offset position, {
    List<String>? paths,
    String? brushType,
    double? brushThickness,
    String? brushColor,
    Size? size,
    Content? content,
  }) {
    _nodeLog.fine("Creating node...");
    UiNode node;
    switch (type) {
      case UiNodes.info:
        node = InfoUiNode(position: position, content: content);
        break;
      case UiNodes.task:
        node = TaskUiNode(position: position);
        break;
      case UiNodes.drawing:
        node = DrawingUiNode(
          position: position,
          paths: paths ?? const [],
          brushType: brushType ?? 'pen',
          brushThickness: brushThickness ?? 4.0,
          brushColor: brushColor ?? '#00E5FF',
        );
        break;
      default:
        throw ArgumentError('Unsupported or unhandled node type: $type');
    }
    String id = node.id;
    controller.store.nodeLookup[id] = node;
    controller.spatial.spatialGrid.insert(id, position);
    controller.spatial.saveConfirmedPosition(id, position);

    // Resolve the node style immediately so it doesn't render with a transparent/stale fallback style
    controller.styleUpdater?.updateStyleForNode(id);

    // Compute the correct initial size and lineCount using the centralized layout strategy helper
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;

    final cmd = CreateNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      node: node,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.nodeAdded,
      ),
    );
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
      tableName:
          node.tableName, // Use canonical name instead of hardcoded string
      node: node,
      controller: controller,
    );

    // OPTIMISTIC TEARDOWN
    controller.store.nodeLookup.remove(id);
    controller.spatial.spatialGrid.remove(id, node.position);
    controller.spatial.clearConfirmedPosition(id);

    // Queue command with immediate execution
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.nodeDeleted,
      ),
    );
    controller.triggerUpdate();
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Tracks the last confirmed DB position to prevent "Superseded Rollback Traps".
  void updateNodePosition(String id, Offset newPosition) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    // Track the LAST confirmed position if this is a new sequence of moves
    final confirmedPos =
        controller.spatial.getConfirmedPosition(id) ?? node.position;
    controller.spatial.saveConfirmedPosition(id, confirmedPos);

    final oldPosition = node.position;
    controller.spatial.spatialGrid.update(id, node.position, newPosition);
    node.position = newPosition;

    final cmd = MoveNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldPosition: oldPosition,
      newPosition: newPosition,
    );

    // Write immediately — no debounce
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.position,
        payload: newPosition,
      ),
    );
  }

  /// Updates node width based on left and right edges.
  /// Calculates width and updates position if the left edge moved.
  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldPosition = node.position;
    final oldSize = node.size;
    final oldStyle = node.style;

    final newWidth = rightEdge - leftEdge;
    final newPosition = Offset(leftEdge, node.position.dy);

    _nodeLog.fine(
      'UPDATING WIDTH: $id edges [$leftEdge, $rightEdge] -> width $newWidth',
    );

    node.position = newPosition;

    // Use centralized NodeStyleStrategy to dynamically resolve node's populated style,
    // and save manual target width in style config to lock manual mode.
    final resolvedStyle = controller.resolveNodeStyle(node);
    node.style = (node.style ?? resolvedStyle).copyWith(
      width: newWidth.round(),
    );

    // Centralized layout recomputation snaps width, snaps height, and calculates
    // the dynamic line count, fully preventing stale DB states prior to command queuing!
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;

    controller.spatial.spatialGrid.update(id, oldPosition, newPosition);

    final cmd = MoveNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldPosition: oldPosition,
      newPosition: newPosition,
      oldSize: oldSize,
      newSize: node.size,
      oldStyle: oldStyle,
      newStyle: node.style,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: node.size,
      ),
    );
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.position,
        payload: node.position,
      ),
    );
  }

  /// Toggles the node's expanded/collapsed state and recalculates height.
  void toggleNodeExpansion(String id) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldSize = node.size;
    final oldExpanded = node.isExpanded;

    final newExpanded = !oldExpanded;
    node.isExpanded = newExpanded;

    // Recalculate size with centralized strategy helper
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;

    _nodeLog.fine(
      'TOGGLING EXPANSION: $id oldExpanded=$oldExpanded -> newExpanded=$newExpanded, newSize=${node.size}',
    );

    final cmd = MoveNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldSize: oldSize,
      newSize: node.size,
      oldExpanded: oldExpanded,
      newExpanded: newExpanded,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.expansion,
        payload: newExpanded,
      ),
    );
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: node.size,
      ),
    );
  }
}
