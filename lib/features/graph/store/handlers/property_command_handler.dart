import '../../models/models.dart';
import '../../models/commands/graph_command_context.dart';
import '../modules/graph_text_mutations.dart';
import '../modules/graph_style_mutations.dart';
import '../modules/graph_tag_mutations.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Command handler managing entity properties: styles, tags, comments, and text content.
class PropertyCommandHandler {
  final GraphCommandContext context;
  late final GraphTextMutations text;
  late final GraphStyleMutations style;
  late final GraphTagMutations tags;

  PropertyCommandHandler(this.context) {
    text = GraphTextMutations(context);
    style = GraphStyleMutations(context);
    tags = GraphTagMutations(context);
  }

  void commitEntityText(
    RawUuid id,
    dynamic newTextOrContent, {
    dynamic originalTextOrContent,
  }) => text.commitEntityText(
    id,
    newTextOrContent,
    originalTextOrContent: originalTextOrContent,
  );

  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent) =>
      text.updateEntityTextLive(id, newTextOrContent);

  void updateNodeStyle(RawUuid id, NodeStyle newStyle) =>
      style.updateNodeStyle(id, newStyle);

  void updateNodesStyle(
    List<RawUuid> ids,
    NodeStyle Function(NodeStyle style) updateFn,
  ) => style.updateNodesStyle(ids, updateFn);

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
