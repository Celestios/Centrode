import 'package:centrode/shared/logging.dart';
import '../../models/models.dart';
import '../../models/commands/create_tag.dart';
import '../../models/commands/update_tag.dart';
import '../../models/commands/delete_tag.dart';
import '../../models/commands/patch_helpers.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Tag and comment mutation operations for the graph.
class GraphTagMutations {
  final Logger _log = Logger('GraphTagMutations');
  final CommandQueueProcessor controller;

  GraphTagMutations(this.controller);

  void updateNodeTags(RawUuid id, List<Tag> newTags) {
    _log.info('Updating tags for $id: $newTags');
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

  void updateNodeComments(RawUuid id, List<frb.Comment> newComments) {
    _log.info('Updating comments for $id: $newComments');
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
    final api = controller.syncEngine.api;
    final List<Tag> rawTags = await api.getAllTags();
    return rawTags;
  }

  Future<void> createTag(Tag tag) async {
    final api = controller.syncEngine.api;
    final cmd = CreateTagCommand(
      targetId: RawUuid.fromString(tag.key.key.uuid),
      api: api,
      tag: tag,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
  }

  Future<void> updateTag(Tag tag) async {
    final api = controller.syncEngine.api;
    final tags = await getAllTags();
    final oldTag = tags.firstWhere((t) => t.key == tag.key, orElse: () => tag);
    final cmd = UpdateTagCommand(
      targetId: RawUuid.fromString(tag.key.key.uuid),
      api: api,
      oldTag: oldTag,
      newTag: tag,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

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
    final api = controller.syncEngine.api;
    final tags = await getAllTags();
    final tag = tags.firstWhere((t) => t.key.key.uuid == tagKey);
    final cmd = DeleteTagCommand(
      targetId: RawUuid.fromString(tagKey),
      api: api,
      tag: tag,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    for (final node in controller.store.nodeLookup.values) {
      if (node is InfoUiNode) {
        final originalCount = node.tags.length;
        final updatedTags = node.tags
            .where((t) => t.key.key.uuid != tagKey)
            .toList();
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

  void addTagToNode(RawUuid nodeId, String name, int color) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newTag = Tag(
        key: parseTypedRecordId('Tag', RawUuid.v4()),
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

  void removeTagFromNode(RawUuid nodeId, String tagKey) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedTags = node.tags
          .where((t) => t.key.key.uuid != tagKey)
          .toList();
      updateNodeTags(nodeId, updatedTags);
    }
  }

  void addCommentToNode(RawUuid nodeId, String text) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final newComment = frb.Comment(
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      updateNodeComments(nodeId, [newComment, ...node.comments]);
    }
  }

  void removeCommentFromNode(RawUuid nodeId, frb.Comment comment) {
    final node = controller.store.nodeLookup[nodeId];
    if (node is InfoUiNode) {
      final updatedComments = node.comments.where((c) => c != comment).toList();
      updateNodeComments(nodeId, updatedComments);
    }
  }
}
