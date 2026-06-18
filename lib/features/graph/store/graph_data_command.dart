import '../models/models.dart';

abstract interface class GraphDataCommand {
  void deleteNode(String id);
  void deleteRelation(String id);
  void updateRelationsLayout(List<String> ids, {String? strategyType});
  void updateNodesStyle(List<String> ids, NodeStyle Function(NodeStyle style) updateFn);
  void addTagToNode(String nodeId, String name, int color);
  void removeTagFromNode(String nodeId, String tagKey);
  void addCommentToNode(String nodeId, String text);
  void removeCommentFromNode(String nodeId, Comment comment);
  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent});
  void updateEntityTextLive(String id, dynamic newTextOrContent);
}
