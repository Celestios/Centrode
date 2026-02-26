import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';

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
/// - [handleIdSwap]: ID swap coordination for optimistic creation
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
  final Uuid _uuid = const Uuid();

  /// Temporary cache to prevent premature disposal of UI state during deletion.
  /// ViewState instances are held here until FFI confirms deletion is final,
  /// enabling efficient rehydration on rollback without creating new memory pointers.
  final Map<String, NodeViewState> _quarantineCache = {};

  /// Creates a node optimistically with immediate UI injection (T=0.0ms pattern).
  /// Returns the tempId synchronously to maintain optimistic UI.
  String createNode(
    UiNodeType type,
    Offset position, {
    void Function(String tempId, String realId)? onIdSwap,
  }) {
    final tempId = "temp_${_uuid.v4()}";
    _nodeLog.fine('Optimistic Injection: $tempId at $position');

    // 1. Instantiate UI Model based on type
    UiNode node;
    switch (type) {
      case UiNodeType.task:
        node = TaskUiNode(
          id: tempId,
          position: position,
          text: "New Task",
          state: "TODO",
        );
        break;
      case UiNodeType.inter:
        node = InterUiNode(id: tempId, position: position, verb: "connects");
        break;
      case UiNodeType.info:
        node = InfoUiNode(id: tempId, position: position, text: "New Note");
        break;
    }

    // 2. Inject into UI immediately (T=0) - Optimistic Pattern
    nodeLookup[tempId] = node;
    final viewState = NodeViewState(node);
    viewStates[tempId] = viewState;
    spatialGrid.insert(tempId, position);
    saveConfirmedPosition(tempId, position); // Save temp ID position

    // 3. Detached Background Sync
    _syncCreateNode(tempId, node, viewState, onIdSwap);

    return tempId;
  }

  /// Detached async worker for FFI bridging
  Future<void> _syncCreateNode(
    String tempId,
    UiNode node,
    NodeViewState viewState,
    void Function(String, String)? onIdSwap,
  ) async {
    try {
      _nodeLog.fine('FFI Dispatch: Creating node for tempId: $tempId'); // [NEW]
      final realId = await api.createNode(input: node.toInput());

      // Ensure node and viewstate still exist before swapping, they might have been deleted mid-process
      final activeNode = nodeLookup[tempId];
      final activeVs = viewStates[tempId];

      if (activeNode != null && activeVs != null) {
        activeNode.id = realId;
        handleIdSwap(tempId, realId, activeNode, activeVs, onIdSwap);
        _nodeLog.info('ID SWAP SUCCESS: $tempId -> $realId'); // [MODIFIED]
      }
    } catch (e) {
      _nodeLog.severe(
        'ID SWAP FAILED: Rolling back $tempId. Error: $e',
      ); // [MODIFIED]
      // Rollback: Remove optimistic entries
      nodeLookup.remove(tempId);
      final vs = viewStates.remove(tempId);
      vs?.dispose();
      spatialGrid.remove(tempId, node.position);
      clearConfirmedPosition(tempId);

      _nodeLog.fine(
        'ROLLBACK: Removed optimistic node, viewState, and spatial entries for $tempId.',
      ); // [NEW]

      onError("Creation failed: $e");
    }
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
          node.rustTable, // Use canonical name instead of hardcoded string
      nodeData: node,
      spatialGrid: spatialGrid,
      onUndo: (restoredNode) {
        _nodeLog.warning('Deletion rejected. Re-hydrating node: $id');

        // ROLLBACK: Pull from quarantine instead of creating new memory pointers
        final quarantinedVs = _quarantineCache.remove(id);
        if (quarantinedVs != null) {
          _nodeLog.fine(
            'QUARANTINE: Node $id ViewState recovered from _quarantineCache.',
          ); // [NEW]
          quarantinedVs.rehydrate(restoredNode);
          viewStates[id] = quarantinedVs;
        } else {
          // Fallback if quarantine was cleared erroneously
          viewStates[id] = NodeViewState(restoredNode);
        }

        nodeLookup[id] = restoredNode;
        spatialGrid.insert(id, restoredNode.position);
        notifyListeners(); // Force canvas rebuild to re-mount the rehydrated node
      },
    );

    // 2. OPTIMISTIC TEARDOWN (Move to quarantine instead of disposing)
    nodeLookup.remove(id);
    _quarantineCache[id] = viewStates.remove(id)!; // Preserve memory pointers
    _nodeLog.fine(
      'QUARANTINE: Node $id ViewState moved to _quarantineCache.',
    ); // [NEW]
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

    final cmd = MoveNodeCommand(
      targetId: id,
      newPosition: newPosition,
      rollbackPosition: confirmedPos,
      nodeViewState: viewState,
      spatialGrid: spatialGrid,
      api: api,
      tableName: node.rustTable, // Use canonical name
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: (pos) {
        node.position = pos;
        movementNotifier.pulse(); // Visually snap vectors back
      },
    );

    // Update optimistic local state (Persistent model)
    final oldPosition = node.position;
    spatialGrid.update(id, oldPosition, newPosition);
    node.position = newPosition;

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
    ); // [NEW]

    // Capture the current node state for rollback
    final capturedNode = node;

    // A. The Data Projection Pattern: Update the mathematical domain model
    final updatedNode = node.copyWith(position: newPosition);
    nodeLookup[id] = updatedNode;

    // B. Create command for immediate FFI sync via CommandProcessor
    final cmd = MoveNodeCommand(
      targetId: id,
      newPosition: newPosition,
      rollbackPosition: oldPosition,
      nodeViewState: viewState,
      spatialGrid: spatialGrid,
      api: api,
      tableName: updatedNode.rustTable, // Use canonical name
      onSuccess: () => saveConfirmedPosition(id, newPosition),
      onUndo: (pos) {
        // Restore the old node in the lookup (domain model rollback)
        nodeLookup[id] = capturedNode;
        movementNotifier.pulse(); // Visually snap vectors back
      },
    );

    // C. Queue with immediate execution (bypasses debounce, maintains FIFO)
    processor.queueCommand(cmd, immediate: true);
    _nodeLog.finer('Position command queued for $id (Immediate).'); // [NEW]
  }
}
