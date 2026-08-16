import 'dart:ui';
import '../models/models.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

abstract interface class GraphDataCommand {
  Future<void> deleteNode(RawUuid id);
  Future<void> deleteRelation(RawUuid id);
  RawUuid createNode(
    UiNodes type,
    Offset position, {
    RawUuid? parentContainerId,
    List<String>? paths,
    String? brushType,
    double? brushThickness,
    String? brushColor,
    Size? size,
    Content? content,
  });
  void updateRelationsLayout(List<RawUuid> ids, {String? strategyType});
  void updateNodesStyle(
    List<RawUuid> ids,
    NodeStyle Function(NodeStyle style) updateFn,
  );
  void addTagToNode(RawUuid nodeId, String name, int color);
  void removeTagFromNode(RawUuid nodeId, String tagKey);
  void addCommentToNode(RawUuid nodeId, String text);
  void removeCommentFromNode(RawUuid nodeId, Comment comment);
  void commitEntityText(
    RawUuid id,
    dynamic newTextOrContent, {
    dynamic originalTextOrContent,
  });
  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent);
  void convertNodeToContainer(RawUuid id);
  RawUuid createFrameFromSelection(Iterable<RawUuid> nodeIds, {Offset? defaultPosition});
  RawUuid? groupNodes(Iterable<RawUuid> nodeIds);
  void ungroupNodes(Iterable<RawUuid> nodeIds);
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String tagKey);
}
