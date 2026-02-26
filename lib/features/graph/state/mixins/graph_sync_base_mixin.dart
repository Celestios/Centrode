import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../domain/models.dart';
import '../../../../src/rust/bridge/stream.dart';
import '../../../../src/rust/domain/base_models.dart' show BoundingBox;
import '../command_processor.dart';
import '../theme_controller.dart';

import 'graph_store_mixin.dart';
import 'graph_spatial_mixin.dart';

/// Tier 3 Base: FFI coordination foundation.
///
/// This mixin provides the core infrastructure for FFI coordination and
/// write-behind debouncing. It holds the [api], [processor], [themeController],
/// and [onError] callback that other sync mixins depend on.
///
/// ## Architecture
///
/// The `GraphSyncBaseMixin` serves as the foundation for the specialized
/// sync mixins:
/// - **GraphNodeMutationsMixin**: Node creation, deletion, position updates
/// - **GraphRelationMutationsMixin**: Relation creation
/// - **GraphPropertyMutationsMixin**: Text and aesthetics updates
///
/// ## Key Patterns
///
/// ### Optimistic Updates (T=0.0ms Pattern)
/// Operations inject into the UI immediately, then sync with the Rust backend
/// asynchronously. On failure, changes are rolled back.
///
/// ### ID Swap Pattern
/// Temporary IDs (`temp_*`) are used for optimistic node creation. When the
/// Rust backend returns a real ID, all dependent structures are updated atomically.
///
/// ### Write-Behind Debouncing
/// High-frequency operations (position updates during drag) are debounced
/// with a 300ms delay via [CommandProcessor] to batch FFI calls.
///
/// See also:
/// - [GraphNodeMutationsMixin] for node mutation operations
/// - [GraphRelationMutationsMixin] for relation mutation operations
/// - [GraphPropertyMutationsMixin] for property mutation operations
mixin GraphSyncBaseMixin on ChangeNotifier, GraphStoreMixin, GraphSpatialMixin {
  final Logger _syncLog = Logger('GraphSyncMixin');

  // Late initialization strictly handled by the composition root.
  late final dynamic api;
  late final CommandProcessor processor;
  late final ThemeController themeController;
  late final void Function(String) onError;

  // NEW: The reactive bounding box updated asynchronously by Rust
  // Uses default bounds of 5000x5000 centered at origin
  final ValueNotifier<BoundingBox> canvasBounds = ValueNotifier(
    const BoundingBox(minX: -2500, minY: -2500, maxX: 2500, maxY: 2500),
  );

  StreamSubscription? _graphStreamSub;

  /// Returns the database table name for a given node type.
  /// Uses strict type checking to ensure no "info_node" strings leak through.
  /// This overrides the base implementation in GraphStoreMixin.
  @override
  String getTableName(UiNode node) {
    if (node is InfoUiNode) return "inode";
    if (node is TaskUiNode) return "task_node";
    if (node is InterUiNode) return "inter_node";
    throw UnimplementedError("Table mapping missing for ${node.runtimeType}");
  }

  /// Fetches the fresh state from Rust.
  /// Synchronizes [GraphStoreMixin] and [GraphSpatialMixin].
  Future<void> loadGraph() async {
    try {
      // Connect to the asynchronous event bus from Rust
      _graphStreamSub ??= api.createGraphStream().listen(_handleGraphEvent);

      final snapshot = await api.getGraphSnapshot();

      nodeLookup.clear();
      relationLookup.clear();

      for (final ffiNode in snapshot.$1) {
        final uiNode = UiNode.fromFFI(ffiNode);
        nodeLookup[uiNode.id] = uiNode;
      }

      for (final ffiRel in snapshot.$2) {
        final uiRel = UiRelation.fromFFI(ffiRel);
        relationLookup[uiRel.id] = uiRel;
      }

      syncViewStates();
    } catch (e) {
      _syncLog.severe('Failed to load graph snapshot', e);
      onError("Failed to load graph: $e");
    }
  }

  /// Handles incoming graph events from the Rust stream.
  /// Updates local state based on asynchronous boundary updates.
  void _handleGraphEvent(GraphEvent event) {
    // Map the FFI generated union to the local reactive state
    switch (event) {
      case GraphEvent_BoundaryUpdated(:final field0):
        // NEW: Explicitly print the integer bounds to prove dynamic expansion
        _syncLog.fine(
          'Elastic Boundaries updated from Core: minX:${field0.minX}, maxX:${field0.maxX}, minY:${field0.minY}, maxY:${field0.maxY}',
        );
        canvasBounds.value = BoundingBox(
          minX: field0.minX,
          minY: field0.minY,
          maxX: field0.maxX,
          maxY: field0.maxY,
        );
      case _:
        // Other events handled by their respective mixins
        break;
    }
  }

  /// Internal handler for the ID swap after successful node creation in Rust.
  /// This method ensures all dependent structures are updated atomically
  /// with respect to the new real ID.
  void handleIdSwap(
    String tempId,
    String realId,
    UiNode activeNode,
    NodeViewState activeVs,
    void Function(String tempId, String realId)? onIdSwap,
  ) {
    _syncLog.fine('Executing ID Swap: $tempId -> $realId');

    // 1. Update GraphStore (Nodes map)
    nodeLookup.remove(tempId);
    nodeLookup[realId] = activeNode;

    // 2. Update SpatialIndexer (ViewStates map) and the ViewState itself
    viewStates.remove(tempId);
    activeVs.updateId(realId); // CRITICAL: Update the internal ID
    viewStates[realId] = activeVs;

    // 3. Update SpatialHashGrid entries
    spatialGrid.remove(tempId, activeNode.position);
    spatialGrid.insert(realId, activeNode.position);

    // 4. Update volatile position tracking (critical for rollback safety)
    final confirmedPos = getConfirmedPosition(tempId);
    if (confirmedPos != null) {
      saveConfirmedPosition(realId, confirmedPos);
    }
    clearConfirmedPosition(tempId);

    // 5. Notify CommandProcessor of ID swap to update pending commands
    processor.notifyIdSwap(tempId, realId);

    // 6. Invoke callback for external state updates
    onIdSwap?.call(tempId, realId);
  }

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  /// Flushes all pending commands synchronously.
  ///
  /// This method cancels all pending debounced operations and clears the
  /// execution queue without executing them. Use this when you need to
  /// immediately stop all pending writes (e.g., before disposal or when
  /// switching contexts).
  void flushSync() => processor.flushSync();

  /// Disposes all resources held by this mixin.
  ///
  /// This method ensures all pending commands are flushed before disposal
  /// to prevent data loss. The [CommandProcessor] is cleaned up synchronously.
  ///
  /// Note: This does NOT dispose the [ThemeController] as it may be shared
  /// with other components. Its disposal is the responsibility of the owner.
  void disposeSync() {
    processor.flushSync();
    _graphStreamSub?.cancel();
    canvasBounds.dispose();
  }
}
