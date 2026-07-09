import 'dart:async';
import 'package:mycelium/shared/logging.dart';

import '../../models/models.dart';
import '../../../../src/rust/bridge/stream.dart';
import '../../../../src/rust/domain/base_models.dart'
    show BoundingBox, MapData, ViewportState;
import '../command_processor.dart';
import '../graph_data_controller.dart';
import '../graph_data_query.dart';

/// Handles communication between the local store/spatial structures and the Rust backend.
class GraphSyncEngine {
  final Logger _syncLog = Logger('GraphSyncEngine');

  final GraphDataController controller;
  final dynamic api;
  final CommandProcessor processor;
  MapData? _lastLoadedMetadata;

  // The reactive bounding box updated asynchronously by Rust
  BoundingBox canvasBounds = const BoundingBox(minX: -500, minY: -500, maxX: 500, maxY: 500);

  StreamSubscription? _graphStreamSub;

  GraphSyncEngine({
    required this.controller,
    required this.api,
    required this.processor,
  });

  /// Get the latest saved viewport state of the map
  /// Which will be the initial viewport state of the current loaded map
  ViewportState? get savedViewportState {
    if (_lastLoadedMetadata == null) return null;
    final vp = _lastLoadedMetadata!.viewportState;
    return ViewportState(
      xOffset: vp.xOffset,
      yOffset: vp.yOffset,
      zoomLevel: vp.zoomLevel,
      activeView: vp.activeView,
    );
  }

  /// Updates the cached viewport state in memory so that subsequent queries return the latest values.
  void updateSavedViewportState(ViewportState state) {
    if (_lastLoadedMetadata != null) {
      _lastLoadedMetadata = MapData(
        mapName: _lastLoadedMetadata!.mapName,
        viewportState: state,
        activeThemeId: _lastLoadedMetadata!.activeThemeId,
        displayMode: _lastLoadedMetadata!.displayMode,
      );
    }
  }

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
      _lastLoadedMetadata = snapshot.metadata;

      _syncLog.info(
        'Snapshot received: ${snapshot.nodes.length} nodes, ${snapshot.relations.length} relations.',
      );

      controller.store.clearStore();

      for (final ffiNode in snapshot.nodes) {
        final uiNode = UiNode.fromRust(ffiNode);
        controller.store.nodeLookup[uiNode.id] = uiNode;
        _hydrateNode(uiNode);
      }

      for (final ffiRel in snapshot.relations) {
        final uiRel = UiRelation.fromRust(ffiRel);
        controller.store.relationLookup[uiRel.id] = uiRel;
      }

      _syncLog.fine('Hydration complete. Seeding spatial index.');

      // Seed the passive spatial index with the new node positions
      controller.spatial.reindexAll(controller.store.nodeLookup);

      controller.publishUpdate(
        GraphEntityUpdate(id: '', tableName: '', type: GraphUpdateType.reset),
      );
    } catch (e) {
      _syncLog.severe('Failed to load graph snapshot', e);
      controller.onError("Failed to load graph: $e");
    }
  }

  /// Handles incoming graph events from the Rust stream.
  /// Updates local state based on asynchronous boundary updates.
  void _handleGraphEvent(GraphEvent event) {
    _syncLog.info('FFI EVENT: Incoming $event');

    switch (event) {
      case GraphEvent_BoundaryUpdated(:final field0):
        _syncLog.fine(
          'Elastic Boundaries updated from Core: minX:${field0.minX}, maxX:${field0.maxX}, minY:${field0.minY}, maxY:${field0.maxY}',
        );
        canvasBounds = BoundingBox(
          minX: field0.minX,
          minY: field0.minY,
          maxX: field0.maxX,
          maxY: field0.maxY,
        );
        controller.publishUpdate(
          GraphEntityUpdate(
            id: '',
            tableName: '',
            type: GraphUpdateType.boundary,
            payload: canvasBounds,
          ),
        );
        break;

      case GraphEvent_NodeUpdated(:final field0):
        final uiNode = UiNode.fromRust(field0);
        final existing = controller.store.nodeLookup[uiNode.id];
        if (existing != null) {
          final oldPos = existing.position;
          // Merge core layout and position properties from the FFI event
          existing.position = uiNode.position;
          existing.size = uiNode.size;
          existing.lineCount = uiNode.lineCount;
          existing.isExpanded = uiNode.isExpanded;
          existing.content = uiNode.content;
          existing.layer = uiNode.layer;
          existing.style = uiNode.style;
          existing.resolvedStyle = uiNode.resolvedStyle;
          existing.layout = uiNode.layout;
          existing.resolvedLayout = uiNode.resolvedLayout;

          if (existing is InfoUiNode && uiNode is InfoUiNode) {
            existing.aliases = uiNode.aliases;
            existing.attachment = uiNode.attachment;
            // Crucial: preserve existing.tags and existing.comments to avoid overwriting them with unhydrated lists!
          } else if (existing is TaskUiNode && uiNode is TaskUiNode) {
            existing.state = uiNode.state;
            existing.dueDate = uiNode.dueDate;
          }

          _hydrateNode(existing);

          controller.spatial.spatialGrid.update(
            existing.id,
            oldPos,
            existing.position,
          );
          controller.spatial.saveConfirmedPosition(
            existing.id,
            existing.position,
          );
        } else {
          controller.store.nodeLookup[uiNode.id] = uiNode;

          _hydrateNode(uiNode);

          controller.spatial.spatialGrid.insert(uiNode.id, uiNode.position);
          controller.spatial.saveConfirmedPosition(uiNode.id, uiNode.position);
        }
        controller.publishUpdate(
          GraphEntityUpdate(
            id: uiNode.id,
            tableName: uiNode.tableName,
            type: GraphUpdateType.reset,
          ),
        );
        break;

      case GraphEvent_NodeDeleted(:final field0):
        final existing = controller.store.nodeLookup[field0];
        if (existing != null) {
          final pos =
              controller.spatial.getConfirmedPosition(field0) ??
              existing.position;
          controller.spatial.spatialGrid.remove(field0, pos);
          controller.spatial.clearConfirmedPosition(field0);
          controller.store.nodeLookup.remove(field0);
        }
        controller.publishUpdate(
          GraphEntityUpdate(
            id: field0,
            tableName: '',
            type: GraphUpdateType.nodeDeleted,
          ),
        );
        break;

      case _:
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
      _syncLog.info('Undo successful');
      await controller.loadGraph();
      await controller.updateHistoryStatus();
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
      _syncLog.info('Redo successful');
      await controller.loadGraph();
      await controller.updateHistoryStatus();
    } else {
      _syncLog.info('Nothing to redo');
    }
  }

  /// Disposes all resources held by this sync engine.
  void dispose() {
    processor.flushSync();
    _graphStreamSub?.cancel();
  }

  void _hydrateNode(UiNode node) {
    // 1. Hydrate content blocks only when they represent truly unparsed plain text:
    //    - Empty blocks, OR
    //    - Single paragraph block with one unmarked inline element (no block-level formatting)
    if (node.content.blocks.isEmpty ||
        (node.content.blocks.length == 1 &&
            node.content.blocks[0].blockType == BlockType.paragraph &&
            node.content.blocks[0].attrs == null &&
            node.content.blocks[0].content.length == 1 &&
            (node.content.blocks[0].content[0].marks == null ||
                node.content.blocks[0].content[0].marks!.isEmpty))) {
      node.content = ContentFactory.fromText(node.text);
    }

    // 2. Resolve style strategies (this sets node.resolvedStyle)
    controller.styleUpdater?.updateStyleForNode(node.id);

    // 3. Recalculate size and line count using TextPainter (layout strategy)
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;
  }
}
