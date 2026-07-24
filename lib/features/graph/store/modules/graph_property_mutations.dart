import '../../models/models.dart';
import '../command_queue_processor.dart';
import 'graph_text_mutations.dart';
import 'graph_style_mutations.dart';
import 'graph_tag_mutations.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/shared/domain/raw_uuid.dart';

/// Property mutation operations for the graph.
/// Facade that delegates to focused mutation modules.
class GraphPropertyMutations {
  final CommandQueueProcessor controller;
  late final GraphTextMutations text;
  late final GraphStyleMutations style;
  late final GraphTagMutations tags;

  GraphPropertyMutations(this.controller) {
    text = GraphTextMutations(controller);
    style = GraphStyleMutations(controller);
    tags = GraphTagMutations(controller);
  }

  void commitEntityText(RawUuid id, dynamic newTextOrContent, {dynamic originalTextOrContent}) =>
      text.commitEntityText(id, newTextOrContent, originalTextOrContent: originalTextOrContent);

  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent) =>
      text.updateEntityTextLive(id, newTextOrContent);

  void updateNodeStyle(RawUuid id, NodeStyle newStyle) =>
      style.updateNodeStyle(id, newStyle);

  void updateNodesStyle(List<RawUuid> ids, NodeStyle Function(NodeStyle style) updateFn) =>
      style.updateNodesStyle(ids, updateFn);

  void updateRelationStyle(RawUuid id, RelationStyle newStyle) =>
      style.updateRelationStyle(id, newStyle);

  void updateNodeTags(RawUuid id, List<Tag> newTags) =>
      tags.updateNodeTags(id, newTags);

  void updateNodeComments(RawUuid id, List<frb.Comment> newComments) =>
      tags.updateNodeComments(id, newComments);

  Future<List<Tag>> getAllTags() => tags.getAllTags();

  Future<void> createTag(Tag tag) => tags.createTag(tag);

  Future<void> updateTag(Tag tag) => tags.updateTag(tag);

  Future<void> deleteTag(String tagKey) => tags.deleteTag(tagKey);

  void addTagToNode(RawUuid nodeId, String name, int color) =>
      tags.addTagToNode(nodeId, name, color);

  void removeTagFromNode(RawUuid nodeId, String tagKey) =>
      tags.removeTagFromNode(nodeId, tagKey);

  void addCommentToNode(RawUuid nodeId, String text) =>
      tags.addCommentToNode(nodeId, text);

  void removeCommentFromNode(RawUuid nodeId, frb.Comment comment) =>
      tags.removeCommentFromNode(nodeId, comment);
}
