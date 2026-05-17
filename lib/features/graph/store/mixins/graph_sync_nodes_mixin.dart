import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import '../../presentation/view_state.dart';
import 'graph_store_mixin.dart';
import 'graph_spatial_mixin.dart';
import 'graph_sync_base_mixin.dart';

/// Node mutation operations for the graph sync hierarchy.
///
/// This mixin provides node-related mutation operations including:
/// - **createNode**: Optimistic node creation with ID swap pattern
/// - **deleteNode**: Node deletion with rollback support
/// - **updateNodePosition**: Position updates with write-behind debouncing
/// - **commitNodePosition**: Position persistence with viewport culling
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
/// ### Rollback Coordination
/// Position rollback requires atomic updates across:
/// - [SpatialHashGrid.update()]
/// - [NodeViewState.positionNotifier.value]
/// - [UiNode.position]
/// - [MovementNotifier.pulse()]
///
/// See also:
/// - [GraphSyncBaseMixin] for the foundation infrastructure
/// - [GraphRelationMutationsMixin] for relation operations
/// - [GraphPropertyMutationsMixin] for property operations
mixin GraphNodeMutationsMixin
    on ChangeNotifier, GraphStoreMixin, GraphSpatialMixin, GraphSyncBaseMixin {
  final Logger _nodeLog = Logger('GraphNodeMutationsMixin');

  /// Temporary cache to prevent premature disposal of UI state during deletion.
  /// ViewState instances are held here until FFI confirms deletion is final,
  /// enabling efficient rehydration on rollback without creating new memory pointers.
  final Map<String, NodeViewState> _quarantineCache = {};

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
    final viewState = NodeViewState(node);
    viewStates[id] = viewState;
    spatialGrid.insert(id, position);
    saveConfirmedPosition(id, position);

    final cmd = CreateNodeCommand(
      targetId: id,
      api: api,
      node: node,
      onUndo: () {
        _nodeLog.warning('Creation rejected or failed. Removing node: $id');
        nodeLookup.remove(id);
        viewStates.remove(id);
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
  ///
  /// Uses [CommandProcessor.queueCommand] with `immediate: true` to ensure
  /// FIFO ordering while bypassing the debounce timer for deletions.
  ///
  /// Implements the Quarantine Pattern: ViewState is moved to [_quarantineCache]
  /// instead of being disposed, preserving memory pointers for efficient rehydration
  /// on rollback without causing widget detachment.
  Future<void> deleteNode(String id) async {
    final node = nodeLookup[id];
    final vs = viewStates[id];
    if (node == null || vs == null) return;

    _nodeLog.info('Initiating optimistic UI teardown for node: $id');

    // 1. Prepare Command for FFI with quarantine-aware rollback
    final cmd = DeleteNodeCommand(
      targetId: id,
      api: api,
      tableName:
          node.tableName, // Use canonical name instead of hardcoded string
      onUndo: () {
        _nodeLog.warning('Deletion rejected. Re-hydrating node: $id');

        // ROLLBACK: Pull from quarantine instead of creating new memory pointers
        final quarantinedVs = _quarantineCache.remove(id);
        if (quarantinedVs != null) {
          _nodeLog.fine(
            'QUARANTINE: Node $id ViewState recovered from _quarantineCache.',
          );
          quarantinedVs.rehydrate(node);
          viewStates[id] = quarantinedVs;
        } else {
          // Fallback if quarantine was cleared erroneously
          viewStates[id] = NodeViewState(node);
        }

        nodeLookup[id] = node;
        spatialGrid.insert(id, node.position);
        notifyListeners(); // Force canvas rebuild to re-mount the rehydrated node
      },
    );

    // 2. OPTIMISTIC TEARDOWN (Move to quarantine instead of disposing)
    nodeLookup.remove(id);
    _quarantineCache[id] = viewStates.remove(id)!; // Preserve memory pointers
    _nodeLog.fine('QUARANTINE: Node $id ViewState moved to _quarantineCache.');
    spatialGrid.remove(id, node.position);
    clearConfirmedPosition(id);

    // 3. Queue command with immediate execution to ensure delete runs before pending moves
    processor.queueCommand(cmd, immediate: true);
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Tracks the last confirmed DB position to prevent "Superseded Rollback Traps".
  void updateNodePosition(String id, Offset newPosition) {
    final node = nodeLookup[id];
    final viewState = viewStates[id];
    if (node == null || viewState == null) return;

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
        viewState.positionNotifier.value = oldPosition;
        spatialGrid.update(id, newPosition, oldPosition);
        movementNotifier.pulse();
      },
    );

    // Queue command with debouncing (300ms delay)
    processor.queueCommand(cmd);
  }

  /// Commits a node position change from drag end, updating spatial hash.
  /// This is the primary method for position persistence with viewport culling.
  /// Implements the Data Projection Pattern to prevent stale payload issues.
  ///
  /// Uses [CommandProcessor.queueCommand] with `immediate: true` to ensure
  /// FIFO ordering while bypassing the debounce timer for position commits.
  Future<void> commitNodePosition(String id) async {
    final node = nodeLookup[id];
    final viewState = viewStates[id];

    if (node == null || viewState == null) return;

    final newPosition = viewState.positionNotifier.value;
    final oldPosition = node.position;

    _nodeLog.fine(
      'COMMITTING POSITION: $id moving $oldPosition -> $newPosition',
    );
    node.position = newPosition;
    nodeLookup[id] = node;

    // B. Create command for immediate FFI sync via CommandProcessor
    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: api,
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        nodeLookup[id] = node;
        viewState.positionNotifier.value = oldPosition;
        spatialGrid.update(id, newPosition, oldPosition);
        movementNotifier.pulse();
      },
    );

    // C. Queue with immediate execution (bypasses debounce, maintains FIFO)
    processor.queueCommand(cmd, immediate: true);
    _nodeLog.finer('Position command queued for $id (Immediate).');
  }

  /// Updates node width based on left and right edges.
  /// Calculates width and updates position if the left edge moved.
  void updateNodeWidth(String id, double leftEdge, double rightEdge) {
    final node = nodeLookup[id];
    final viewState = viewStates[id];
    if (node == null || viewState == null) return;

    final oldPosition = node.position;
    final oldSize = node.size;

    final newWidth = rightEdge - leftEdge;
    final newPosition = Offset(leftEdge, node.position.dy);

    _nodeLog.fine(
      'UPDATING WIDTH: $id edges [$leftEdge, $rightEdge] -> width $newWidth',
    );

    node.position = newPosition;
    node.size = Size(newWidth, node.size.height);
    viewState.onContentOrStyleChanged(node);

    spatialGrid.update(id, oldPosition, newPosition);

    final cmd = MoveNodeCommand(
      targetId: id,
      newNode: node,
      api: api,
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: () {
        node.position = oldPosition;
        node.size = oldSize;
        viewState.positionNotifier.value = oldPosition;
        viewState.sizeNotifier.value = node.size;
        spatialGrid.update(id, newPosition, oldPosition);
        movementNotifier.pulse();
      },
    );

    processor.queueCommand(cmd, immediate: true);
  }
}
