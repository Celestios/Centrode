import 'dart:ui';
import '../../models/models.dart';
import '../graph_data_controller.dart';
import '../graph_data_query.dart';

/// Style mutation operations for the graph.
class GraphStyleMutations {
  final GraphDataController controller;

  GraphStyleMutations(this.controller);

  void updateNodeStyle(String id, NodeStyle newStyle) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldStyle = node.style;
    final oldSize = node.size;

    node.style = newStyle;
    controller.styleUpdater?.updateStyleForNode(id);

    final newSizeResult = controller.calculateNodeSize(node);
    final newSize = newSizeResult.size;
    node.size = newSize;
    node.lineCount = newSizeResult.lineCount;

    controller.syncEngine.processor.queueCommand(
      UpdateNodeStyleCommand(
        targetId: id,
        tableName: node.tableName,
        api: controller.syncEngine.api,
        oldStyle: oldStyle,
        newStyle: newStyle,
        oldSize: oldSize,
        newSize: newSize,
        controller: controller,
      ),
    );

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.style,
        payload: newStyle,
      ),
    );
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: newSize,
      ),
    );
  }

  void updateNodesStyle(List<String> ids, NodeStyle Function(NodeStyle style) updateFn) {
    if (ids.isEmpty) return;

    final Map<String, NodeStyle> oldStyles = {};
    final Map<String, NodeStyle> newStyles = {};
    final Map<String, Size> oldSizes = {};
    final Map<String, Size> newSizes = {};

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
    controller.syncEngine.processor.queueCommand(cmd);

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

  void updateRelationStyle(String id, RelationStyle newStyle) {
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

    final cmd = UpdateRelationLayoutCommand(
      targetId: id,
      tableName: 'IRelation',
      gateway: controller.relationGateway,
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
