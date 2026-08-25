import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/nodes.dart';
import 'package:centrode/src/rust/domain/contents.dart';
import '../../models/models.dart';
import '../../models/commands/graph_command_context.dart';
import '../../models/commands/patch_helpers.dart';
import '../modules/graph_node_mutations.dart';
import '../api/node_api.dart';
import '../command_processor.dart';

/// Command handler managing node creation, movement, deletion, and cache synchronization.
class NodeCommandHandler {
  final Logger _log = Logger('NodeCommandHandler');
  final GraphCommandContext context;
  final NodeApi api;
  final CommandProcessor processor;
  late final GraphNodeMutations mutations;

  NodeCommandHandler({
    required this.context,
    required this.api,
    required this.processor,
  }) {
    mutations = GraphNodeMutations(context);
  }

  void syncNodeCache(
    RawUuid id, [
    Offset? positionOverride,
    Size? sizeOverride,
  ]) {
    final node = context.store.nodeLookup[id];
    if (node != null) {
      final pos = positionOverride ?? node.position;
      final size = sizeOverride ?? node.size;
      api.updateNodeCachePositions(
        positions: [
          (
            parseTypedRecordId(node.tableName, id),
            pos.dx,
            pos.dy,
            size.width,
            size.height,
          ),
        ],
      );
    }
    context.relationEngine.onNodeMoved(id);
  }

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
    Attachment? attachment,
    MediaType? mediaType,
  }) {
    return mutations.createNode(
      type,
      position,
      parentContainerId: parentContainerId,
      paths: paths,
      brushType: brushType,
      brushThickness: brushThickness,
      brushColor: brushColor,
      size: size,
      content: content,
      attachment: attachment,
      mediaType: mediaType,
    );
  }

  Future<void> deleteNode(RawUuid id) => mutations.deleteNode(id);

  void updateNodePosition(RawUuid id, Offset newPosition) {
    mutations.updateNodePosition(id, newPosition);
    syncNodeCache(id, newPosition);
  }

  void reparentNode(RawUuid id, RawUuid? targetParentId, Offset targetPos) {
    mutations.reparentNode(id, targetParentId, targetPos);
    syncNodeCache(id, targetPos);
  }

  void updateNodePositionsVolatile(List<(RawUuid, Offset)> updates) {
    final List<(TypedRecordId, double, double, double, double)> positions = [];
    for (final update in updates) {
      final id = update.$1;
      final newPos = update.$2;
      final node = context.store.nodeLookup[id];
      if (node != null) {
        positions.add((
          parseTypedRecordId(node.tableName, id),
          newPos.dx,
          newPos.dy,
          node.size.width,
          node.size.height,
        ));
      }
    }
    if (positions.isNotEmpty) {
      api.updateNodeCachePositions(positions: positions);
      for (final update in updates) {
        context.relationEngine.onNodeMoved(update.$1);
      }
    }
  }

  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) {
    mutations.updateNodeWidth(id, leftEdge, rightEdge);
    syncNodeCache(id);
  }

  void toggleNodeExpansion(RawUuid id) {
    mutations.toggleNodeExpansion(id);
    syncNodeCache(id);
  }

  void convertNodeToContainer(RawUuid id) {
    mutations.convertNodeToContainer(id);
    context.relationEngine.onNodeMoved(id);
  }

  RawUuid createFrameFromSelection(Iterable<RawUuid> nodeIds, {Offset? defaultPosition}) {
    final frameId = mutations.createFrameFromSelection(nodeIds, defaultPosition: defaultPosition);
    context.relationEngine.onNodeMoved(frameId);
    return frameId;
  }

  RawUuid? groupNodes(Iterable<RawUuid> nodeIds) {
    return mutations.groupNodes(nodeIds);
  }

  void ungroupNodes(Iterable<RawUuid> nodeIds) {
    mutations.ungroupNodes(nodeIds);
  }

  void setContainerClosed(RawUuid id, bool isClosed) {
    mutations.setContainerClosed(id, isClosed);
  }
}
