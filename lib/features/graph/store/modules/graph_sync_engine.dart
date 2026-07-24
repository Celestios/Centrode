import 'dart:async';
import 'dart:ui';
import 'package:mycelium/shared/logging.dart';

import '../../models/models.dart';
import '../../../../src/rust/bridge/stream.dart';
import '../../../../src/rust/domain/patches.dart';
import '../command_queue_processor.dart';
import '../command_processor.dart';
import '../graph_data_query.dart';
import '../graph_api.dart';

/// Handles communication between the local store/spatial structures and the Rust backend.
class GraphSyncEngine {
  final Logger _syncLog = Logger('GraphSyncEngine');

  final CommandQueueProcessor controller;
  final GraphApi api;
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
  /// Updates local state based on patch-based incremental updates.
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
        controller.queryController.canvasBounds = canvasBounds;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: '',
            tableName: '',
            type: GraphUpdateType.boundary,
            payload: canvasBounds,
          ),
        );
        break;

      case GraphEvent_NodeUpdated(:final id, :final patches):
        _applyNodePatches(id, patches);
        break;

      case GraphEvent_RelationUpdated(:final id, :final patches):
        _applyRelationPatches(id, patches);
        break;

      case GraphEvent_BatchUpdated(:final field0):
        _applyGraphDelta(field0);
        break;
    }
  }

  void _applyNodePatches(dynamic id, List<dynamic> patches) {
    final idStr = id.toString();
    final existing = controller.store.nodeLookup[idStr];
    if (existing == null) return;

    final oldPos = existing.position;
    for (final patch in patches) {
      if (patch is NodePatch_Position) {
        final coords = patch.field0;
        existing.position = Offset(coords.x.toDouble(), coords.y.toDouble());
      } else if (patch is NodePatch_Size) {
        final sz = patch.field0;
        existing.size = Size(sz.width.toDouble(), sz.height.toDouble());
      } else if (patch is NodePatch_Content) {
        existing.content = patch.field0;
      } else if (patch is NodePatch_IsExpanded) {
        existing.isExpanded = patch.field0;
      } else if (patch is NodePatch_Style) {
        existing.style = patch.field0;
      } else if (patch is NodePatch_Significance) {
        existing.significance = patch.field0;
      } else if (patch is NodePatch_TaskState && existing is TaskUiNode) {
        existing.state = patch.field0;
      }
    }

    controller.spatial.spatialGrid.update(existing.id, oldPos, existing.position);
    controller.spatial.saveConfirmedPosition(existing.id, existing.position);
    controller.publishUpdate(
      GraphEntityUpdate(id: existing.id, tableName: existing.tableName, type: GraphUpdateType.reset),
    );
  }

  void _applyRelationPatches(dynamic id, List<dynamic> patches) {
    final idStr = id.toString();
    final existing = controller.store.relationLookup[idStr];
    if (existing == null) return;

    for (final patch in patches) {
      if (patch is RelationPatch_Verb) {
        existing.verb = patch.field0;
      } else if (patch is RelationPatch_Style) {
        existing.style = patch.field0;
      } else if (patch is RelationPatch_Layout) {
        existing.layout = patch.field0;
      } else if (patch is RelationPatch_Directionless) {
        existing.directionless = patch.field0;
      }
    }

    controller.publishUpdate(
      GraphEntityUpdate(id: existing.id, tableName: 'IRelation', type: GraphUpdateType.reset),
    );
  }

  void _applyGraphDelta(GraphDelta delta) {
    _syncLog.info('Applying GraphDelta: ${delta.nodeCreations.length} creations, '
        '${delta.nodeUpserts.length} upserts, ${delta.nodeDeletions.length} deletions');

    for (final nodeId in delta.nodeDeletions) {
      final idStr = nodeId.toString();
      final node = controller.store.nodeLookup.remove(idStr);
      if (node != null) {
        controller.spatial.spatialGrid.remove(idStr, node.position);
      }
    }
    for (final relId in delta.relationDeletions) {
      controller.store.relationLookup.remove(relId.toString());
    }

    for (final ffiNode in delta.nodeCreations) {
      final uiNode = UiNode.fromRust(ffiNode);
      controller.store.nodeLookup[uiNode.id] = uiNode;
      _hydrateNode(uiNode);
      controller.spatial.spatialGrid.insert(uiNode.id, uiNode.position);
      controller.spatial.saveConfirmedPosition(uiNode.id, uiNode.position);
    }
    for (final ffiRel in delta.relationCreations) {
      final uiRel = UiRelation.fromRust(ffiRel);
      controller.store.relationLookup[uiRel.id] = uiRel;
    }

    for (final entry in delta.nodeUpserts) {
      _applyNodePatches(entry.$1, entry.$2);
    }
    for (final entry in delta.relationUpserts) {
      _applyRelationPatches(entry.$1, entry.$2);
    }

    controller.publishUpdate(
      GraphEntityUpdate(id: '', tableName: '', type: GraphUpdateType.reset),
    );
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

  /// Undoes the last operation.
  /// The BatchUpdated event from Rust applies the inverse delta incrementally.
  Future<void> undo() async {
    _syncLog.info('Requesting Undo');
    await flush();
    final record = await api.undo();
    if (record != null) {
      _syncLog.info('Undo successful');
      await controller.updateHistoryStatus();
    } else {
      _syncLog.info('Nothing to undo');
    }
  }

  /// Redoes the last undone operation.
  /// The BatchUpdated event from Rust applies the forward delta incrementally.
  Future<void> redo() async {
    _syncLog.info('Requesting Redo');
    await flush();
    final record = await api.redo();
    if (record != null) {
      _syncLog.info('Redo successful');
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
