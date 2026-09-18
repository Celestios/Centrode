import 'dart:async';
import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import '../api/history_api.dart';
import '../command_processor.dart';
import '../modules/graph_store.dart';
import '../modules/graph_spatial.dart';
import '../relation_engine_state.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/patches.dart';

/// Command handler managing undo/redo history operations and status synchronization.
class HistoryCommandHandler {
  final Logger _log = Logger('HistoryCommandHandler');
  final HistoryApi _api;
  final CommandProcessor _processor;
  final GraphStore _store;
  final GraphSpatial _spatial;
  final RelationEngineState _relationEngine;
  final void Function()? onHistoryUpdated;

  int _undoCount = 0;
  int _redoCount = 0;

  HistoryCommandHandler({
    required HistoryApi api,
    required CommandProcessor processor,
    required GraphStore store,
    required GraphSpatial spatial,
    required RelationEngineState relationEngine,
    this.onHistoryUpdated,
  })  : _api = api,
        _processor = processor,
        _store = store,
        _spatial = spatial,
        _relationEngine = relationEngine;

  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  /// Fetches and updates latest undo/redo counts from the backend.
  Future<void> updateHistoryStatus() async {
    _undoCount = await _api.undoCount();
    _redoCount = await _api.redoCount();
    onHistoryUpdated?.call();
  }

  /// Executes an undo operation on the backend and reconciles in-memory lookups.
  Future<void> undo() async {
    _log.info('Executing undo');
    await _processor.flush();
    final record = await _api.undo();
    if (record != null) {
      final delta = await _api.applyHistoryRecordPatch(
        record: record,
        isForward: false,
      );
      if (delta != null) {
        _applyDelta(delta);
      }
    }
    await updateHistoryStatus();
  }

  /// Executes a redo operation on the backend and reconciles in-memory lookups.
  Future<void> redo() async {
    _log.info('Executing redo');
    await _processor.flush();
    final record = await _api.redo();
    if (record != null) {
      final delta = await _api.applyHistoryRecordPatch(
        record: record,
        isForward: true,
      );
      if (delta != null) {
        _applyDelta(delta);
      }
    }
    await updateHistoryStatus();
  }

  /// Applies a GraphDelta to in-memory lookups and invalidates affected caches.
  void _applyDelta(GraphDelta delta) {
    _log.info(
      'Applying delta: ${delta.nodeCreations.length} creations, '
      '${delta.nodeUpserts.length} upserts, '
      '${delta.nodeDeletions.length} deletions',
    );

    for (final nodeId in delta.nodeDeletions) {
      final rawId = RawUuid.fromString(nodeId.key.uuid);
      final node = _store.nodeLookup.remove(rawId);
      if (node != null) {
        _spatial.spatialGrid.remove(rawId, node.position);
      }
    }
    for (final relId in delta.relationDeletions) {
      final rawId = RawUuid.fromString(relId.key.uuid);
      _store.relationLookup.remove(rawId);
      _relationEngine.onRelationDeleted(rawId);
    }

    for (final ffiNode in delta.nodeCreations) {
      final uiNode = UiNode.fromRust(ffiNode);
      _store.nodeLookup[uiNode.id] = uiNode;
      _spatial.spatialGrid.insert(uiNode.id, uiNode.position);
    }
    for (final ffiRel in delta.relationCreations) {
      final uiRel = UiRelation.fromRust(ffiRel);
      _store.relationLookup[uiRel.id] = uiRel;
      _relationEngine.onRelationAdded(uiRel);
    }

    for (final entry in delta.nodeUpserts) {
      final rawId = RawUuid.fromString(entry.$1.key.uuid);
      final existing = _store.nodeLookup[rawId];
      if (existing == null) continue;
      final oldPos = existing.position;
      for (final patch in entry.$2) {
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
        }
      }
      _spatial.spatialGrid.update(rawId, oldPos, existing.position);
    }
    for (final entry in delta.relationUpserts) {
      final rawId = RawUuid.fromString(entry.$1.key.uuid);
      final existing = _store.relationLookup[rawId];
      if (existing == null) continue;
      for (final patch in entry.$2) {
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
      _relationEngine.onRelationLayoutUpdated(rawId);
    }

    for (final nodeId in delta.nodeDeletions) {
      final rawId = RawUuid.fromString(nodeId.key.uuid);
      final relIds = _relationEngine.tracker.getRelationIdsForNode(rawId);
      for (final relIdStr in relIds) {
        final relId = RawUuid.fromString(relIdStr);
        _relationEngine.onRelationDeleted(relId);
      }
    }
  }
}
