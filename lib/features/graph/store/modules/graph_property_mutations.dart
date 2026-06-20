import 'dart:ui';
import 'package:mycelium/infrastructure/telemetry/logging.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../graph_data_controller.dart';
import '../graph_data_query.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;

/// Property mutation operations for the graph.
class GraphPropertyMutations {
  final Logger _propLog = Logger('GraphPropertyMutations');
  final GraphDataController controller;

  GraphPropertyMutations(this.controller);

  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent}) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    final Content newContent = newTextOrContent is Content
        ? newTextOrContent
        : ContentFactory.fromText(newTextOrContent as String);

    final Content oldContent = originalTextOrContent is Content
        ? originalTextOrContent
        : (originalTextOrContent is String
            ? ContentFactory.fromText(originalTextOrContent)
            : (node?.content ?? ContentFactory.empty()));

    _propLog.info(
      'Committing text for $id: "${newContent.text}"',
    );

    // If the text didn't actually change, no-op
    if (node != null && _contentEquals(oldContent, newContent)) {
      return;
    }
    if (rel != null && oldContent.text == newContent.text) {
      return;
    }

    // Capture the pre-edit size of the node
    Size? preEditSize;
    if (node != null) {
      final oldContentBackup = node.content;
      node.content = oldContent;
      preEditSize = controller.calculateNodeSize(node).size;
      node.content = oldContentBackup;
    } else {
      preEditSize = node?.size;
    }

    // 1. Ensure the optimistic memory state is completely up-to-date
    if (node != null) {
      node.content = newContent;
      final result = controller.calculateNodeSize(node);
      node.size = result.size;
      node.lineCount = result.lineCount;
    } else if (rel != null) {
      rel.verb = newContent.text;
    }

    // 3. Queue command with primitive rollback
    controller.syncEngine.processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node?.tableName ?? 'IRelation',
        api: controller.syncEngine.api,
        oldContent: node == null ? null : oldContent,
        newContent: node == null ? null : newContent,
        oldSize: node == null ? null : preEditSize,
        newSize: node?.size,
        oldVerb: rel == null ? null : oldContent.text,
        newVerb: rel == null ? null : newContent.text,
        controller: controller,
      ),
    );

    if (node != null) {
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.size,
          payload: node.size,
        ),
      );
    } else if (rel != null) {
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
    }
  }

  /// Updates the entity text locally in memory without triggering FFI/database sync.
  /// This is used for buttery smooth, real-time visual canvas resizing as the user types.
  void updateEntityTextLive(String id, dynamic newTextOrContent) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    final Content newContent = newTextOrContent is Content
        ? newTextOrContent
        : ContentFactory.fromText(newTextOrContent as String);

    if (node != null) {
      if (_contentEquals(node.content, newContent)) {
        return;
      }
      node.content = newContent;
      final result = controller.calculateNodeSize(node, isEditing: true);
      node.size = result.size;
      node.lineCount = result.lineCount;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.size,
          payload: node.size,
        ),
      );
    } else if (rel != null) {
      if (rel.verb == newContent.text) return;
      rel.verb = newContent.text;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
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

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.tags,
        payload: newTags,
      ),
    );
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

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.comments,
        payload: newComments,
      ),
    );
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
          controller.publishUpdate(
            GraphEntityUpdate(
              id: node.id,
              tableName: node.tableName,
              type: GraphUpdateType.tags,
              payload: updatedTags,
            ),
          );
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
          controller.publishUpdate(
            GraphEntityUpdate(
              id: node.id,
              tableName: node.tableName,
              type: GraphUpdateType.tags,
              payload: updatedTags,
            ),
          );
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

  void addTagToNode(String nodeId, String name, int color) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newTag = Tag(
        key: const Uuid().v4(),
        fields: TagFields(
          name: name,
          color: color,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      updateNodeTags(nodeId, [...node.tags, newTag]);
    }
  }

  void removeTagFromNode(String nodeId, String tagKey) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedTags = node.tags.where((t) => t.key != tagKey).toList();
      updateNodeTags(nodeId, updatedTags);
    }
  }

  void addCommentToNode(String nodeId, String text) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final newComment = Comment(
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      updateNodeComments(nodeId, [newComment, ...node.comments]);
    }
  }

  void removeCommentFromNode(String nodeId, Comment comment) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedComments = node.comments.where((c) => c != comment).toList();
      updateNodeComments(nodeId, updatedComments);
    }
  }

  bool _contentEquals(Content a, Content b) {
    if (a.text != b.text) return false;
    if (a.blocks.length != b.blocks.length) return false;
    for (int i = 0; i < a.blocks.length; i++) {
      final ba = a.blocks[i];
      final bb = b.blocks[i];
      if (ba.blockType != bb.blockType) return false;
      if (ba.attrs != bb.attrs) return false;
      if (ba.content.length != bb.content.length) return false;
      for (int j = 0; j < ba.content.length; j++) {
        final ia = ba.content[j];
        final ib = bb.content[j];
        if (ia.inlineType != ib.inlineType) return false;
        if (ia.text != ib.text) return false;
        
        final marksA = ia.marks;
        final marksB = ib.marks;
        if (marksA == null && marksB == null) continue;
        if (marksA == null || marksB == null) return false;
        if (marksA.length != marksB.length) return false;
        for (int k = 0; k < marksA.length; k++) {
          final ma = marksA[k];
          final mb = marksB[k];
          if (ma.markType != mb.markType) return false;
          if (ma.attrs != mb.attrs) return false;
        }
      }
    }
    return true;
  }
}
