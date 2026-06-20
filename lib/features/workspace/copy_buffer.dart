import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/src/rust/domain/styles.dart' show RelationLayout;

class CopyBuffer extends ChangeNotifier {
  List<UiNode>? _nodes;
  List<UiRelation>? _relations;
  Offset? _copyOrigin;

  bool get hasData => _nodes != null && _nodes!.isNotEmpty;

  List<UiNode>? get nodes => _nodes;
  List<UiRelation>? get relations => _relations;
  Offset? get copyOrigin => _copyOrigin;

  void copy(List<String> selectedIds, GraphDataQuery dataQuery) {
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
        .where((r) =>
            selectedSet.contains(r.fromNodeId) &&
            selectedSet.contains(r.toNodeId))
        .toList();

    final oldToNewId = <String, String>{};
    final newNodes = <UiNode>[];
    for (final node in selectedNodes) {
      final newId = const Uuid().v4();
      oldToNewId[node.id] = newId;
      final copy = _copyNodeWithId(node, newId);
      if (copy == null) continue;
      newNodes.add(copy);
    }

    final newRelations = <UiRelation>[];
    for (final rel in selectedRelations) {
      final newFromId = oldToNewId[rel.fromNodeId];
      final newToId = oldToNewId[rel.toNodeId];
      if (newFromId == null || newToId == null) continue;
      if (rel is InfoUiRelation) {
        newRelations.add(rel.copyWith(
          id: const Uuid().v4(),
          fromNodeId: newFromId,
          toNodeId: newToId,
        ));
      }
    }

    double sumX = 0, sumY = 0;
    for (final node in newNodes) {
      sumX += node.position.dx;
      sumY += node.position.dy;
    }
    _copyOrigin = Offset(
      sumX / newNodes.length,
      sumY / newNodes.length,
    );

    _nodes = newNodes;
    _relations = newRelations;
    notifyListeners();
  }

  Future<List<String>> paste(Offset cursorPosition, GraphDataController controller) async {
    if (!hasData) return [];

    final createdIds = <String>[];
    final copyToPasteId = <String, String>{};

    for (final node in _nodes!) {
      final newId = controller.createNode(
        UiNodes.info,
        cursorPosition + (node.position - _copyOrigin!),
        content: node.content,
        size: node.size,
      );
      copyToPasteId[node.id] = newId;
      createdIds.add(newId);
    }

    await controller.flush();

    for (final rel in _relations!) {
      final newFromId = copyToPasteId[rel.fromNodeId];
      final newToId = copyToPasteId[rel.toNodeId];
      if (newFromId == null || newToId == null) continue;

      final fromNode = controller.nodeLookup[newFromId];
      final toNode = controller.nodeLookup[newToId];
      if (fromNode == null || toNode == null) continue;

      final newRel = InfoUiRelation(
        fromNodeId: newFromId,
        fromNodeTable: fromNode.tableName,
        toNodeId: newToId,
        toNodeTable: toNode.tableName,
        verb: rel.verb,
        layout: const RelationLayout(
          fromSide: 'Auto',
          toSide: 'Auto',
          strategyType: 'default',
        ),
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

  UiNode? _copyNodeWithId(UiNode node, String newId) {
    if (node is InfoUiNode) return node.copyWith(id: newId);
    if (node is TaskUiNode) return node.copyWith(id: newId);
    if (node is CommentUiNode) return node.copyWith(id: newId);
    if (node is DrawingUiNode) return node.copyWith(id: newId);
    if (node is FrameUiNode) return node.copyWith(id: newId);
    if (node is InterUiNode) return node.copyWith(id: newId);
    if (node is MediaUiNode) return node.copyWith(id: newId);
    if (node is ShapeUiNode) return node.copyWith(id: newId);
    return null;
  }
}
