import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/models/graph_relation.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/models/commands/create_node.dart';
import 'package:centrode/shared/traceable_notifier.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class CopyBuffer extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'CopyBuffer';
  List<UiNode>? _nodes;
  List<UiRelation>? _relations;
  Offset? _copyOrigin;

  bool get hasData => _nodes != null && _nodes!.isNotEmpty;

  List<UiNode>? get nodes => _nodes;
  List<UiRelation>? get relations => _relations;
  Offset? get copyOrigin => _copyOrigin;

  void copy(List<RawUuid> selectedIds, GraphDataQuery dataQuery) {
    if (selectedIds.isEmpty) return;

    final selectedNodes = <UiNode>[];
    for (final id in selectedIds) {
      final node = dataQuery.nodeLookup[id];
      if (node != null) {
        selectedNodes.add(node);
      }
    }

    if (selectedNodes.isEmpty) return;

    final selectedSet = selectedIds.toSet();
    final selectedRelations = dataQuery.relationLookup.values
        .where(
          (r) =>
              selectedSet.contains(r.fromNodeId) &&
              selectedSet.contains(r.toNodeId),
        )
        .toList();

    final oldToNewId = <RawUuid, RawUuid>{};
    final newNodes = <UiNode>[];
    for (final node in selectedNodes) {
      final newId = RawUuid.v4();
      oldToNewId[node.id] = newId;
      final copy = node.cloneWithId(newId);
      if (copy == null) continue;
      newNodes.add(copy);
    }

    final newRelations = <UiRelation>[];
    for (final rel in selectedRelations) {
      final newFromId = oldToNewId[rel.fromNodeId];
      final newToId = oldToNewId[rel.toNodeId];
      if (newFromId == null || newToId == null) continue;
      if (rel is InfoUiRelation) {
        newRelations.add(
          rel.copyWith(
            id: RawUuid.v4(),
            fromNodeId: newFromId,
            toNodeId: newToId,
          ),
        );
      }
    }

    double sumX = 0, sumY = 0;
    for (final node in newNodes) {
      sumX += node.position.dx;
      sumY += node.position.dy;
    }
    _copyOrigin = Offset(sumX / newNodes.length, sumY / newNodes.length);

    _nodes = newNodes;
    _relations = newRelations;
    notifyListeners();
  }

  Future<List<RawUuid>> paste(
    Offset cursorPosition,
    CommandQueueProcessor controller,
  ) async {
    if (!hasData) return [];

    final createdIds = <RawUuid>[];
    final copyToPasteId = <RawUuid, RawUuid>{};

    for (final node in _nodes!) {
      final newPos = cursorPosition + (node.position - _copyOrigin!);
      final newNode = _createNodeByType(node, newPos);
      if (newNode == null) continue;

      final id = newNode.id;
      controller.store.nodeLookup[id] = newNode;
      controller.spatial.spatialGrid.insert(id, newPos);
      controller.spatial.saveConfirmedPosition(id, newPos);
      controller.styleUpdater?.updateStyleForNode(id);

      final result = controller.calculateNodeSize(newNode);
      newNode.size = result.size;
      newNode.lineCount = result.lineCount;

      copyToPasteId[node.id] = id;
      createdIds.add(id);

      controller.syncEngine.processor.queueCommand(
        CreateNodeCommand(
          targetId: id,
          api: controller.syncEngine.api,
          node: newNode,
          controller: controller,
        ),
        immediate: true,
      );

      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: newNode.tableName,
          type: GraphUpdateType.nodeAdded,
        ),
      );
    }

    controller.triggerUpdate();

    await controller.flush();

    for (final rel in _relations!) {
      final newFromId = copyToPasteId[rel.fromNodeId];
      final newToId = copyToPasteId[rel.toNodeId];
      if (newFromId == null || newToId == null) continue;

      final fromNode = controller.queryController.nodeLookup[newFromId];
      final toNode = controller.queryController.nodeLookup[newToId];
      if (fromNode == null || toNode == null) continue;

      final newRel = InfoUiRelation(
        fromNodeId: newFromId,
        fromNodeTable: fromNode.tableName,
        toNodeId: newToId,
        toNodeTable: toNode.tableName,
        verb: rel.verb,
        layout: rel.layout,
      );

      controller.store.relationLookup[newRel.id] = newRel;
      controller.styleUpdater?.updateStyleForRelation(newRel.id);

      try {
        await controller.syncEngine.api.createRelation(input: newRel.toRust());
      } catch (_) {}
    }

    controller.triggerUpdate();
    return createdIds;
  }

  void clear() {
    _nodes = null;
    _relations = null;
    _copyOrigin = null;
    notifyListeners();
  }

  UiNode? _createNodeByType(UiNode source, Offset position) {
    final clone = source.cloneWithId(RawUuid.v4());
    if (clone == null) return null;
    clone.position = position;
    return clone;
  }
}
