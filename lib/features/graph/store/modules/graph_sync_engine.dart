import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../models/models.dart';
import '../../../../src/rust/bridge/stream.dart';
import '../../../../src/rust/domain/base_models.dart' show BoundingBox;
import '../command_processor.dart';
import '../../presentation/theme_manager.dart';
import '../graph_data_controller.dart';

/// Handles communication between the local store/spatial structures and the Rust backend.
class GraphSyncEngine {
  final Logger _syncLog = Logger('GraphSyncEngine');
  
  final GraphDataController controller;
  final dynamic api;
  final CommandProcessor processor;
  final ThemeController themeController;

  // The reactive bounding box updated asynchronously by Rust
  // Uses default bounds of 5000x5000 centered at origin
  final ValueNotifier<BoundingBox> canvasBounds = ValueNotifier(
    const BoundingBox(minX: -2500, minY: -2500, maxX: 2500, maxY: 2500),
  );

  StreamSubscription? _graphStreamSub;

  GraphSyncEngine({
    required this.controller,
    required this.api,
    required this.processor,
    required this.themeController,
  });

  /// Fetches the fresh state from Rust.
  /// Synchronizes store and spatial modules.
  Future<void> loadGraph() async {
    try {
      _syncLog.info(
        'Initiating Graph Hydration: Connecting FFI Stream and fetching snapshot.',
      );
      // Connect to the asynchronous event bus from Rust
      _graphStreamSub ??= api.createGraphStream().listen(_handleGraphEvent);

      final snapshot = await api.getGraphSnapshot();

      _syncLog.info(
        'Snapshot received: ${snapshot.$1.length} nodes, ${snapshot.$2.length} relations.',
      );

      controller.store.clearStore();

      for (final ffiNode in snapshot.$1) {
        final uiNode = UiNode.fromRust(ffiNode);
        controller.store.nodeLookup[uiNode.id] = uiNode;
      }

      for (final ffiNode in snapshot.$2) {
        final uiNode = UiNode.fromRust(ffiNode);
        controller.store.nodeLookup[uiNode.id] = uiNode;
      }

      for (final _ in snapshot.$3) {
        _syncLog.warning('InterNodes not yet fully supported in UI');
      }

      for (final ffiRel in snapshot.$4) {
        final uiRel = UiRelation.fromRust(ffiRel);
        controller.store.relationLookup[uiRel.id] = uiRel;
      }

      _syncLog.fine('Hydration complete. Seeding spatial index.');

      // Seed the passive spatial index with the new node positions
      controller.spatial.reindexAll(controller.store.nodeLookup);
    } catch (e) {
      _syncLog.severe('Failed to load graph snapshot', e);
      controller.onError("Failed to load graph: $e");
    }
  }

  /// Handles incoming graph events from the Rust stream.
  /// Updates local state based on asynchronous boundary updates.
  void _handleGraphEvent(GraphEvent event) {
    _syncLog.info(
      'FFI EVENT: Incoming $event',
    ); // instrumentation for all events
    // Map the FFI generated union to the local reactive state
    switch (event) {
      case GraphEvent_BoundaryUpdated(:final field0):
        // Explicitly print the integer bounds to prove dynamic expansion
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
        // Other events handled
        break;
    }
  }

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  /// Flushes all pending commands synchronously by discarding them.
  /// Use this when you need to immediately stop all pending writes.
  void flushSync() => processor.flushSync();

  /// Forces execution of all pending debounced commands immediately.
  /// Use this before operations that require the DB to be up to date (e.g., Undo).
  Future<void> flush() => processor.forceFlush();

  /// Undoes the last operation and refreshes the graph.
  Future<void> undo() async {
    _syncLog.info('Requesting Undo');
    await flush();
    final record = await api.undo();
    if (record != null) {
      _syncLog.info('Undo successful: ${record.actionType}');
      await loadGraph();
    } else {
      _syncLog.info('Nothing to undo');
    }
  }

  /// Redoes the last undone operation and refreshes the graph.
  Future<void> redo() async {
    _syncLog.info('Requesting Redo');
    await flush();
    final record = await api.redo();
    if (record != null) {
      _syncLog.info('Redo successful: ${record.actionType}');
      await loadGraph();
    } else {
      _syncLog.info('Nothing to redo');
    }
  }

  /// Disposes all resources held by this sync engine.
  void dispose() {
    processor.flushSync();
    _graphStreamSub?.cancel();
    canvasBounds.dispose();
  }
}
