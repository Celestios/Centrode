import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import 'graph_store_mixin.dart';
import 'graph_spatial_mixin.dart';
import 'graph_sync_base_mixin.dart';

/// Node mutation operations for the graph sync hierarchy.
///
/// This mixin provides node-related mutation operations including:
/// - **createNode**: Optimistic node creation with ID swap pattern
/// - **deleteNode**: Node deletion with rollback support
/// - **updateNodePosition**: Position updates with write-behind debouncing
/// - **updateNodeWidth**: Width updates from edge dragging
///
/// ## Architecture
///
/// This mixin depends on [GraphSyncBaseMixin] for access to:
/// - [api]: FFI handle for Rust communication
/// - [processor]: Command processor for debounced writes
/// - [onError]: Error callback for failure handling
///
/// ## Key Patterns
///
/// ### Optimistic Creation (T=0.0ms Pattern)
/// Node creation injects into the UI immediately with a temporary ID,
/// then syncs with Rust asynchronously. On success, the temp ID is
/// swapped for the real ID atomically across all data structures.
///
/// See also:
/// - [GraphSyncBaseMixin] for the foundation infrastructure
/// - [GraphRelationMutationsMixin] for relation operations
/// - [GraphPropertyMutationsMixin] for property operations
mixin GraphNodeMutationsMixin
    on ChangeNotifier, GraphStoreMixin, GraphSpatialMixin, GraphSyncBaseMixin {
  final Logger _nodeLog = Logger('GraphNodeMutationsMixin');

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
    nodeLookup[id] = node;
    spatialGrid.insert(id, position);
    saveConfirmedPosition(id, position);

    final cmd = CreateNodeCommand(
      targetId: id,
      api: api,
      node: node,
      onUndo: () {
        _nodeLog.warning('Creation rejected or failed. Removing node: $id');
        nodeLookup.remove(id);
        spatialGrid.remove(id, position);
        clearConfirmedPosition(id);
        notifyListeners();
      },
    );
    processor.queueCommand(cmd, immediate: true);

    notifyListeners();
    return id;
  }

  /// Deletes a node with immediate command execution via CommandProcessor.
  /// Handles deletion race condition by ensuring delete executes before any pending moves.
  Future<void> deleteNode(String id) async {
    final node = nodeLookup[id];
    if (node == null) return;

    _nodeLog.info('Initiating optimistic UI teardown for node: $id');

    // Prepare Command for FFI with rollback
    final cmd = DeleteNodeCommand(
      targetId: id,
      api: api,
      tableName: node.tableName, // Use canonical name instead of hardcoded string
      onUndo: () {
        _nodeLog.warning('Deletion rejected. Re-hydrating node: $id');
        nodeLookup[id] = node;
        spatialGrid.insert(id, node.position);
        notifyListeners(); // Force canvas rebuild to re-mount the rehydrated node
      },
    );

    // OPTIMISTIC TEARDOWN
    nodeLookup.remove(id);
    spatialGrid.remove(id, node.position);
    clearConfirmedPosition(id);

    // Queue command with immediate execution
    processor.queueCommand(cmd, immediate: true);
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Tracks the last confirmed DB position to prevent "Superseded Rollback Traps".
  void updateNodePosition(String id, Offset newPosition) {
    final node = nodeLookup[id];
    if (node == null) return;

    // Track the LAST confirmed position if this is a new sequence of moves
    final confirmedPos = getConfirmedPosition(id) ?? node.position;
    saveConfirmedPosition(id, confirmedPos);

    final oldPosition = node.position;
    spatialGrid.update(id, node.position, newPosition);
    node.position = newPosition;

    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: api,
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        spatialGrid.update(id, newPosition, oldPosition);
        notifyListeners();
      },
    );

    // Queue command with debouncing (300ms delay)
    processor.queueCommand(cmd);
  }

  /// Updates node width based on left and right edges.
  /// Calculates width and updates position if the left edge moved.
  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    final node = nodeLookup[id];
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

    spatialGrid.update(id, oldPosition, newPosition);

    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: api,
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        node.size = oldSize;
        spatialGrid.update(id, newPosition, oldPosition);
        notifyListeners();
      },
    );

    processor.queueCommand(cmd, immediate: true);
  }
}
