import 'dart:ui';
import '../../models/models.dart';
import '../../models/commands/patch_helpers.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Style mutation operations for the graph.
class GraphStyleMutations {
  final CommandQueueProcessor controller;

  GraphStyleMutations(this.controller);

  void updateNodeStyle(RawUuid id, NodeStyle newStyle) {
    updateNodesStyle([id], (_) => newStyle);
  }


  void updateNodesStyle(
    List<RawUuid> ids,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    if (ids.isEmpty) return;

    final Map<RawUuid, NodeStyle> oldStyles = {};
    final Map<RawUuid, NodeStyle> newStyles = {};
    final Map<RawUuid, Size> oldSizes = {};
    final Map<RawUuid, Size> newSizes = {};

    for (final id in ids) {
      final node = controller.store.nodeLookup[id];
      if (node == null) continue;

      final oldStyle = node.style ?? controller.resolveNodeStyle(node);
      final oldSize = node.size;
      final newStyle = updateFn(oldStyle);

      node.style = newStyle;
      controller.styleUpdater?.updateStyleForNode(id);

      final newSizeResult = controller.calculateNodeSize(node);
      final newSize = newSizeResult.size;
      node.size = newSize;
      node.lineCount = newSizeResult.lineCount;

      oldStyles[id] = oldStyle;
      newStyles[id] = newStyle;
      oldSizes[id] = oldSize;
      newSizes[id] = newSize;
    }

    if (newStyles.isEmpty) return;

    final cmd = UpdateNodesStyleCommand(
      targetId: newStyles.keys.first,
      api: controller.syncEngine.api,
      oldStyles: oldStyles,
      newStyles: newStyles,
      oldSizes: oldSizes,
      newSizes: newSizes,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    final List<(TypedRecordId, double, double, double, double)> positions = [];
    for (final id in newStyles.keys) {
      final node = controller.store.nodeLookup[id]!;
      positions.add((
        parseTypedRecordId(node.tableName, id),
        node.position.dx,
        node.position.dy,
        newSizes[id]!.width,
        newSizes[id]!.height,
      ));
    }
    if (positions.isNotEmpty) {
      controller.syncEngine.api.updateNodeCachePositions(positions: positions);
      for (final id in newStyles.keys) {
        controller.relationEngine.onNodeMoved(id);
      }
    }

    for (final id in newStyles.keys) {
      final node = controller.store.nodeLookup[id]!;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.style,
          payload: newStyles[id],
        ),
      );
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.size,
          payload: newSizes[id],
        ),
      );
    }
    controller.triggerUpdate();
  }

  void updateRelationStyle(RawUuid id, RelationStyle newStyle) {
    final relation = controller.store.relationLookup[id];
    if (relation == null) return;

    final oldRelation = UiRelation.copy(relation);
    if (oldRelation == null) return;

    final updatedRelation = (relation as InfoUiRelation).copyWith(
      style: newStyle,
    );
    updatedRelation.resolvedStyle = null;

    controller.store.relationLookup[id] = updatedRelation;
    controller.styleUpdater?.updateStyleForRelation(id);
    controller.relationEngine.onRelationStyleUpdated(id);

    final cmd = UpdateRelationLayoutCommand(
      targetId: id,
      tableName: 'IRelation',
      api: controller.syncEngine.api,
      oldLayout: oldRelation.layout,
      newLayout: updatedRelation.layout,
      oldStyle: oldRelation.style,
      newStyle: newStyle,
      oldRelation: oldRelation,
      controller: controller,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: 'IRelation',
        type: GraphUpdateType.style,
        payload: updatedRelation.style,
      ),
    );

    controller.triggerUpdate();
  }
}
