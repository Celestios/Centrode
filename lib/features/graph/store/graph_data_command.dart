import '../models/models.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

abstract interface class GraphDataCommand {
  void deleteNode(RawUuid id);
  void deleteRelation(RawUuid id);
  void updateRelationsLayout(List<RawUuid> ids, {String? strategyType});
  void updateNodesStyle(List<RawUuid> ids, NodeStyle Function(NodeStyle style) updateFn);
  void addTagToNode(RawUuid nodeId, String name, int color);
  void removeTagFromNode(RawUuid nodeId, String tagKey);
  void addCommentToNode(RawUuid nodeId, String text);
  void removeCommentFromNode(RawUuid nodeId, Comment comment);
  void commitEntityText(RawUuid id, dynamic newTextOrContent, {dynamic originalTextOrContent});
  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent);
}
