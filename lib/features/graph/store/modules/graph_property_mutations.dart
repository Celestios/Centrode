import 'dart:ui';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import '../graph_data_controller.dart';
import '../graph_data_query.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;


/// Property mutation operations for the graph.
class GraphPropertyMutations {
  final Logger _propLog = Logger('GraphPropertyMutations');
  final GraphDataController controller;

  GraphPropertyMutations(this.controller);

  void commitEntityText(String id, String newText, {String? originalText}) {
    _propLog.info('Committing text for $id: "$newText" (original: "$originalText")');
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    // Determine the pre-edited state to check for changes and configure rollbacks
    final String effectiveOriginalText = originalText ?? (node?.content.text ?? rel?.verb ?? '');
    
    // If the text didn't actually change from the original starting text, no-op
    if (effectiveOriginalText == newText) return;

    // Capture the pre-edit size of the node (before any live keystroke resizing occurred)
    Size? preEditSize;
    if (node != null && originalText != null) {
      final oldContent = node.content;
      node.content = ContentFactory.fromText(originalText);
      preEditSize = controller.calculateNodeSize(node);
      // Restore back to current text
      node.content = oldContent;
    } else {
      preEditSize = node?.size;
    }

    // 1. Ensure the optimistic memory state is completely up-to-date
    if (node != null) {
      node.content = ContentFactory.fromText(newText);
      node.size = controller.calculateNodeSize(node);
    } else if (rel != null) {
      rel.verb = newText;
    }

    // 3. Queue command with primitive rollback
    controller.syncEngine.processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node?.tableName ?? 'IRelation',
        api: controller.syncEngine.api,
        oldContent: node == null ? null : ContentFactory.fromText(effectiveOriginalText),
        newContent: node == null ? null : ContentFactory.fromText(newText),
        oldSize: node == null ? null : preEditSize,
        newSize: node?.size,
        oldVerb: rel == null ? null : effectiveOriginalText,
        newVerb: rel == null ? null : newText,
        controller: controller,
      ),
    );

    if (node != null) {
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.text,
        payload: newText,
      ));
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: node.size,
      ));
    } else if (rel != null) {
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: 'IRelation',
        type: GraphUpdateType.text,
        payload: newText,
      ));
    }
  }

  /// Updates the entity text locally in memory without triggering FFI/database sync.
  /// This is used for buttery smooth, real-time visual canvas resizing as the user types.
  void updateEntityTextLive(String id, String newText) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    if (node != null) {
      if (node.content.text == newText) return;
      node.content = ContentFactory.fromText(newText);
      node.size = controller.calculateNodeSize(node);
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.text,
        payload: newText,
      ));
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: node.size,
      ));
    } else if (rel != null) {
      if (rel.verb == newText) return;
      rel.verb = newText;
      controller.publishUpdate(GraphEntityUpdate(
        id: id,
        tableName: 'IRelation',
        type: GraphUpdateType.text,
        payload: newText,
      ));
    }
  }

  /// Updates node aesthetics with snapshot/delta logic and debounced write-behind sync.
  void updateNodeStyle(String id, NodeStyle newStyle) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldStyle = node.style;
    final oldSize = node.size;

    node.style = newStyle;
    controller.styleUpdater?.updateStyleForNode(id);

    // Automatically recalculate node dimensions when styling changes
    final newSize = controller.calculateNodeSize(node);
    node.size = newSize;

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

    controller.publishUpdate(GraphEntityUpdate(
      id: id,
      tableName: node.tableName,
      type: GraphUpdateType.style,
      payload: newStyle,
    ));
    controller.publishUpdate(GraphEntityUpdate(
      id: id,
      tableName: node.tableName,
      type: GraphUpdateType.size,
      payload: newSize,
    ));
  }

  void updateNodeTags(String id, List<Tag> newTags) {
    _propLog.info('Updating tags for $id: $newTags');
    final node = controller.store.nodeLookup[id];
    if (node is! InfoUiNode) return;

    final oldTags = List<Tag>.from(node.tags);

    node.tags = newTags;

    controller.syncEngine.processor.queueCommand(
      UpdateTagsCommand(
        targetId: id,
        tableName: node.tableName,
        api: controller.syncEngine.api,
        oldTags: oldTags,
        newTags: newTags,
        controller: controller,
      ),
    );

    controller.publishUpdate(GraphEntityUpdate(
      id: id,
      tableName: node.tableName,
      type: GraphUpdateType.tags,
      payload: newTags,
    ));
    controller.triggerUpdate();
  }

  void updateNodeComments(String id, List<frb.Comment> newComments) {
    _propLog.info('Updating comments for $id: $newComments');
    final node = controller.store.nodeLookup[id];
    if (node is! InfoUiNode) return;

    final oldComments = List<frb.Comment>.from(node.comments);

    node.comments = newComments;

    controller.syncEngine.processor.queueCommand(
      UpdateCommentsCommand(
        targetId: id,
        api: controller.syncEngine.api,
        node: node,
        oldComments: oldComments,
        controller: controller,
      ),
    );

    controller.publishUpdate(GraphEntityUpdate(
      id: id,
      tableName: node.tableName,
      type: GraphUpdateType.comments,
      payload: newComments,
    ));
    controller.triggerUpdate();
  }

  Future<List<Tag>> getAllTags() async {
    final dynamic api = controller.syncEngine.api;
    final List<dynamic> rawTags = await api.getAllTags();
    return rawTags.cast<Tag>();
  }

  Future<void> createTag(Tag tag) async {
    final dynamic api = controller.syncEngine.api;
    await api.createTag(tag: tag);
    controller.triggerUpdate();
  }

  Future<void> updateTag(Tag tag) async {
    final dynamic api = controller.syncEngine.api;
    await api.updateTag(tag: tag);

    // Update matching tags in-memory in all nodes
    for (final node in controller.store.nodeLookup.values) {
      if (node is InfoUiNode) {
        bool changed = false;
        final updatedTags = node.tags.map((t) {
          if (t.key == tag.key) {
            changed = true;
            return tag;
          }
          return t;
        }).toList();
        if (changed) {
          node.tags = updatedTags;
          controller.publishUpdate(GraphEntityUpdate(
            id: node.id,
            tableName: node.tableName,
            type: GraphUpdateType.tags,
            payload: updatedTags,
          ));
        }
      }
    }
    controller.triggerUpdate();
  }

  Future<void> deleteTag(String tagKey) async {
    final dynamic api = controller.syncEngine.api;
    await api.deleteTag(key: tagKey);

    // Remove deleted tag from all nodes in memory
    for (final node in controller.store.nodeLookup.values) {
      if (node is InfoUiNode) {
        final originalCount = node.tags.length;
        final updatedTags = node.tags.where((t) => t.key != tagKey).toList();
        if (updatedTags.length != originalCount) {
          node.tags = updatedTags;
          controller.publishUpdate(GraphEntityUpdate(
            id: node.id,
            tableName: node.tableName,
            type: GraphUpdateType.tags,
            payload: updatedTags,
          ));
        }
      }
    }
    controller.triggerUpdate();
  }

  /// Updates the style of a relation.
  void updateRelationStyle(String id, RelationStyle newStyle) {
    final relation = controller.store.relationLookup[id];
    if (relation == null) return;

    final oldRelation = UiRelation.copy(relation);
    if (oldRelation == null) return;

    final updatedRelation = (relation as InfoUiRelation).copyWith(
      style: newStyle,
    );
    updatedRelation.resolvedStyle = null;

    // OPTIMISTIC UPDATE
    controller.store.relationLookup[id] = updatedRelation;
    controller.styleUpdater?.updateStyleForRelation(id);

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
