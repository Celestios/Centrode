import 'dart:async';
import 'dart:ui';
import 'package:centrode/shared/logging.dart';

import '../../models/models.dart';
import '../../../../src/rust/bridge/stream.dart';
import '../../../../src/rust/domain/patches.dart';
import '../../../../src/rust/layout_engine/types.dart';
import '../command_queue_processor.dart';
import '../command_processor.dart';
import '../graph_data_query.dart';
import '../graph_api.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'layout_tick_interpolator.dart';

/// Handles communication between the local store/spatial structures and the Rust backend.
class GraphSyncEngine {
  final Logger _syncLog = Logger('GraphSyncEngine');

  final CommandQueueProcessor controller;
  final GraphApi api;
  final CommandProcessor processor;
  final LayoutTickInterpolator _interpolator = LayoutTickInterpolator();
  MapData? _lastLoadedMetadata;

  // The reactive bounding box updated asynchronously by Rust
  BoundingBox canvasBounds = const BoundingBox(
    minX: -500,
    minY: -500,
    maxX: 500,
    maxY: 500,
  );

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
      // Connect to the asynchronous event bus from Rust, ensuring previous subscription is cancelled
      await _graphStreamSub?.cancel();
      _graphStreamSub = api.createGraphStream().listen(_handleGraphEvent);

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

      if (_lastLoadedMetadata?.optArea != null) {
        final box = _lastLoadedMetadata!.optArea!;
        controller.queryController.optAreaNotifier.value = Rect.fromLTRB(
          box.minX,
          box.minY,
          box.maxX,
          box.maxY,
        );
      } else {
        controller.queryController.optAreaNotifier.value = null;
      }

      // Seed the passive spatial index with the new node positions
      controller.spatial.reindexAll(controller.store.nodeLookup);

      controller.publishUpdate(
        GraphEntityUpdate(tableName: '', type: GraphUpdateType.reset),
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

      case GraphEvent_LayoutTick(:final field0):
        _applyLayoutTick(field0);
        break;
    }
  }

  void _applyNodePatches(TypedRecordId id, List<NodePatch> patches) {
    final rawId = RawUuid.fromString(id.key.uuid);
    final existing = controller.store.nodeLookup[rawId];
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

    controller.spatial.spatialGrid.update(
      existing.id,
      oldPos,
      existing.position,
    );
    controller.spatial.saveConfirmedPosition(existing.id, existing.position);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: existing.id,
        tableName: existing.tableName,
        type: GraphUpdateType.reset,
      ),
    );
  }

  void _applyRelationPatches(TypedRecordId id, List<RelationPatch> patches) {
    final rawId = RawUuid.fromString(id.key.uuid);
    final existing = controller.store.relationLookup[rawId];
    if (existing == null) return;

    for (final patch in patches) {
      if (patch is RelationPatch_Verb) {
        existing.verb = patch.field0;
      } else if (patch is RelationPatch_Style) {
        existing.style = patch.field0;
      } else if (patch is RelationPatch_Layout) {
        existing.layout = patch.field0;
      } else if (patch is RelationPatch_Direction) {
        existing.direction = patch.field0;
      }
    }

    controller.publishUpdate(
      GraphEntityUpdate(
        id: existing.id,
        tableName: 'IRelation',
        type: GraphUpdateType.reset,
      ),
    );
  }

  void _applyGraphDelta(GraphDelta delta) {
    _syncLog.info(
      'Applying GraphDelta: ${delta.nodeCreations.length} creations, '
      '${delta.nodeUpserts.length} upserts, ${delta.nodeDeletions.length} deletions',
    );

    for (final nodeId in delta.nodeDeletions) {
      final rawId = RawUuid.fromString(nodeId.key.uuid);
      final node = controller.store.nodeLookup.remove(rawId);
      if (node != null) {
        controller.spatial.spatialGrid.remove(rawId, node.position);
      }
    }
    for (final relId in delta.relationDeletions) {
      controller.store.relationLookup.remove(
        RawUuid.fromString(relId.key.uuid),
      );
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
      GraphEntityUpdate(tableName: '', type: GraphUpdateType.reset),
    );
  }

  void _applyLayoutTick(LayoutTickResult result) {
    _syncLog.fine(
      'LayoutTick: iter=${result.iteration}, energy=${result.energy.toStringAsFixed(2)}, '
      'converged=${result.converged}, posPatches=${result.positionPatches.length}, portPatches=${result.portPatches.length}',
    );

    _interpolator.processTick(
      tick: result,
      store: controller.store,
      onSubStep: (movedNodeIds) {
        final affectedRelations = controller.store.relationLookup.values
            .where(
              (r) =>
                  movedNodeIds.contains(r.fromNodeId) ||
                  movedNodeIds.contains(r.toNodeId),
            )
            .map((r) => r.id);
        controller.relationEngine.markRelationsDirty(affectedRelations);
        controller.publishUpdate(
          GraphEntityUpdate(tableName: '', type: GraphUpdateType.reset),
        );
      },
      onConverged: (convergedTick) {
        _syncLog.info(
          'Layout optimization converged after ${convergedTick.iteration} iterations',
        );
        if (convergedTick.positionPatches.isNotEmpty) {
          controller.spatial.reindexAll(controller.store.nodeLookup);
          controller.publishUpdate(
            GraphEntityUpdate(tableName: '', type: GraphUpdateType.reset),
          );
        }
        _persistLayoutPositions(convergedTick.positionPatches);
        _persistLayoutPorts(convergedTick.portPatches);
      },
    );
  }

  Future<void> _persistLayoutPositions(List<LayoutPatch> patches) async {
    final updates = <(RawUuid, Offset)>[];
    for (final patch in patches) {
      final rawId = RawUuid.fromString(patch.id.key.uuid);
      final newPos = Offset(patch.x, patch.y);
      updates.add((rawId, newPos));
      final node = controller.store.nodeLookup[rawId];
      if (node != null) {
        node.position = newPos;
        controller.spatial.saveConfirmedPosition(rawId, newPos);
      }
    }
    if (updates.isNotEmpty) {
      controller.updateNodePositionsVolatile(updates);
    }
  }

  Future<void> _persistLayoutPorts(List<PortPatch> patches) async {
    for (final patch in patches) {
      final relId = RawUuid.fromString(patch.relationId.key.uuid);
      final rel = controller.store.relationLookup[relId];
      if (rel != null) {
        final oldLayout = rel.layout;
        rel.layout = (oldLayout ?? const RelationLayout(strategyType: 'bezier')).copyWith(
          fromSide: patch.fromSide,
          toSide: patch.toSide,
        );
        controller.relationEngine.onRelationLayoutUpdated(relId);
      }
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
    _interpolator.cancel();
    processor.flushSync();
    _graphStreamSub?.cancel();
    _graphStreamSub = null;
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
