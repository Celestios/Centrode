import 'dart:async';
import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import '../../models/commands/patch_helpers.dart';
import '../../models/models.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../models/node_style_resolver.dart';

/// Node mutation operations for the graph.
class GraphNodeMutations {
  final Logger _nodeLog = Logger('GraphNodeMutations');
  final CommandQueueProcessor controller;

  GraphNodeMutations(this.controller);

  /// Creates a node with immediate UI injection (T=0.0ms pattern).
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
    _nodeLog.fine("Creating node...");
    UiNode node;
    switch (type) {
      case UiNodes.info:
        node = InfoUiNode(
          position: position,
          content: content,
          parentContainerId: parentContainerId,
        );
        break;
      case UiNodes.task:
        node = TaskUiNode(
          position: position,
          parentContainerId: parentContainerId,
        );
        break;
      case UiNodes.drawing:
        node = DrawingUiNode(
          position: position,
          parentContainerId: parentContainerId,
          paths: paths ?? const [],
          brushType: brushType is BrushType
              ? (brushType as BrushType)
              : BrushType.pencil,
          brushThickness: brushThickness ?? 4.0,
          brushColor: brushColor ?? '#00E5FF',
        );
        break;
      case UiNodes.frame:
        node = FrameUiNode(
          position: position,
          parentContainerId: parentContainerId,
          size: size ?? const Size(400.0, 300.0),
          title: 'title',
        );
        break;
      case UiNodes.media:
        node = MediaUiNode(
          position: position,
          parentContainerId: parentContainerId,
          size: size ?? const Size(260.0, 180.0),
          attachment: attachment ??
              Attachment(
                id: RawUuid.v4().toUuidString(),
                hash: 'sample_media_hash',
                name: 'sample_media.png',
                mimeType: 'image/png',
                byteSize: 1024 * 720,
              ),
          mediaType: mediaType ?? MediaType.image,
        );
        break;
      default:
        throw ArgumentError('Unsupported or unhandled node type: $type');
    }
    RawUuid id = node.id;
    controller.store.nodeLookup[id] = node;
    // Resolve the node style immediately so it doesn't render with a transparent/stale fallback style
    controller.styleUpdater?.updateStyleForNode(id);

    // Compute the correct initial size and lineCount using the centralized layout strategy helper
    final result = controller.calculateNodeSize(node);
    node.size = size ?? result.size;
    node.lineCount = result.lineCount;

    final Offset finalPos;
    if (parentContainerId != null) {
      final container = controller.store.nodeLookup[parentContainerId];
      if (container is ContainerUiNode) {
        container.childCount++;
      }
      finalPos = position;
      node.parentContainerId = parentContainerId;
      node.position = finalPos;
      controller.spatial.spatialIndex.insertNode(id, parentContainerId, finalPos, node.size);
    } else {
      // Check if created inside an open container
      final nodeWorldCenter = position + Offset(node.size.width / 2, node.size.height / 2);
      ContainerUiNode? targetContainer;
      for (final candidate in controller.store.nodeLookup.values) {
        if (candidate.id == id || candidate is! ContainerUiNode) continue;
        if (candidate.isClosed) continue;

        final cWorldPos = candidate.getAbsoluteWorldPosition(controller.store.nodeLookup);
        final cRect = Rect.fromLTWH(cWorldPos.dx, cWorldPos.dy, candidate.size.width, candidate.size.height);

        if (cRect.contains(nodeWorldCenter)) {
          targetContainer = candidate;
          break;
        }
      }

      if (targetContainer != null) {
        final cWorldPos = targetContainer.getAbsoluteWorldPosition(controller.store.nodeLookup);
        finalPos = position - cWorldPos;
        node.parentContainerId = targetContainer.id;
        node.position = finalPos;
        targetContainer.childCount++;
        controller.spatial.spatialIndex.insertNode(id, targetContainer.id, finalPos, node.size);
      } else {
        finalPos = position;
        controller.spatial.spatialIndex.insertNode(id, null, position, node.size);
      }
    }

    controller.spatial.saveConfirmedPosition(id, finalPos);

    controller.syncEngine.api.updateNodeCachePositions(
      positions: [
        (
          parseTypedRecordId(node.tableName, id),
          finalPos.dx,
          finalPos.dy,
          node.size.width,
          node.size.height,
        ),
      ],
    );

    final cmd = CreateNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      node: node,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.nodeAdded,
      ),
    );
    controller.triggerUpdate();
    return id;
  }

  /// Deletes a node with immediate command execution via CommandProcessor.
  /// Handles deletion race condition by ensuring delete executes before any pending moves.
  Future<void> deleteNode(RawUuid id) async {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    _nodeLog.info('Initiating optimistic UI teardown for node: $id');

    // Prepare Command for FFI with rollback
    final cmd = DeleteNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      tableName:
          node.tableName, // Use canonical name instead of hardcoded string
      node: node,
      controller: controller,
    );

    // OPTIMISTIC TEARDOWN
    controller.store.nodeLookup.remove(id);
    controller.spatial.spatialIndex.removeNode(id, node.parentContainerId, node.position);
    if (node.parentContainerId != null) {
      final parentContainer = controller.store.nodeLookup[node.parentContainerId];
      if (parentContainer is ContainerUiNode && parentContainer.childCount > 0) {
        parentContainer.childCount--;
      }
    }
    controller.spatial.clearConfirmedPosition(id);

    final connectedRelations = controller.store.relationLookup.values
        .where((r) => r.fromNodeId == id || r.toNodeId == id)
        .toList();
    for (final rel in connectedRelations) {
      controller.store.relationLookup.remove(rel.id);
      controller.relationEngine.onRelationDeleted(rel.id);
      controller.publishUpdate(
        GraphEntityUpdate(
          id: rel.id,
          tableName: 'IRelation',
          type: GraphUpdateType.relationDeleted,
        ),
      );
    }

    // Queue command with immediate execution
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.nodeDeleted,
      ),
    );
    controller.triggerUpdate();
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Updates node position with container auto-adoption and spatial index migration.
  void updateNodePosition(RawUuid id, Offset newPosition) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldPosition = node.position;
    final oldParentId = node.parentContainerId;

    // Track the LAST confirmed position if this is a new sequence of moves
    final confirmedPos =
        controller.spatial.getConfirmedPosition(id) ?? node.position;
    controller.spatial.saveConfirmedPosition(id, confirmedPos);

    final targetPos = newPosition;
    if (node.position == targetPos) return;

    if (oldParentId == null) {
      controller.spatial.spatialGrid.update(id, node.position, targetPos, node.size);
    } else {
      controller.spatial.spatialIndex.updateNode(id, oldParentId, node.position, targetPos, node.size);
    }
    node.position = targetPos;

    final cmd = PatchNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldPosition: oldPosition,
      newPosition: targetPos,
    );

    // Write immediately — no debounce
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.position,
        payload: targetPos,
      ),
    );
  }

  /// Programmatically migrates a node to a different parent container scope.
  void reparentNode(RawUuid id, RawUuid? targetParentId, Offset targetPos) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldParentId = node.parentContainerId;
    final oldPosition = node.position;
    if (oldParentId == targetParentId && node.position == targetPos) return;

    controller.spatial.spatialIndex.migrateNodeSpatialGrid(
      id,
      oldParentId,
      targetParentId,
      oldPosition,
      targetPos,
      node.size,
    );

    if (oldParentId != null) {
      final oldParent = controller.store.nodeLookup[oldParentId];
      if (oldParent is ContainerUiNode && oldParent.childCount > 0) {
        oldParent.childCount--;
      }
    }
    if (targetParentId != null) {
      final newParent = controller.store.nodeLookup[targetParentId];
      if (newParent is ContainerUiNode) {
        newParent.childCount++;
      }
    }

    node.parentContainerId = targetParentId;
    node.position = targetPos;

    final cmd = PatchNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldPosition: oldPosition,
      newPosition: targetPos,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.position,
        payload: targetPos,
      ),
    );
  }

  /// Updates node width based on left and right edges.
  /// Calculates width and updates position if the left edge moved.
  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldPosition = node.position;
    final oldSize = node.size;
    final oldStyle = node.style;

    final newWidth = rightEdge - leftEdge;
    final newPosition = Offset(leftEdge, node.position.dy);

    _nodeLog.fine(
      'UPDATING WIDTH: $id edges [$leftEdge, $rightEdge] -> width $newWidth',
    );

    node.position = newPosition;
    node.size = Size(newWidth, node.size.height);

    // Use centralized NodeStyleStrategy to dynamically resolve node's populated style,
    // and save manual target width in style config to lock manual mode.
    final resolvedStyle = node.resolvedStyle ?? resolveStyle(node);
    node.style = (node.style ?? resolvedStyle).copyWith(
      width: newWidth.round(),
    );

    // Centralized layout recomputation snaps width, snaps height, and calculates
    // the dynamic line count, fully preventing stale DB states prior to command queuing!
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;

    controller.spatial.spatialGrid.update(id, oldPosition, newPosition, node.size);

    final cmd = PatchNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldPosition: oldPosition,
      newPosition: newPosition,
      oldSize: oldSize,
      newSize: node.size,
      oldStyle: oldStyle,
      newStyle: node.style,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.size,
        payload: node.size,
      ),
    );
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.position,
        payload: node.position,
      ),
    );
  }

  /// Toggles the node's expanded/collapsed state and recalculates height.
  void toggleNodeExpansion(RawUuid id) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;

    final oldSize = node.size;
    final oldExpanded = node.isExpanded;

    final newExpanded = !oldExpanded;
    node.isExpanded = newExpanded;

    // Recalculate size with centralized strategy helper
    final result = controller.calculateNodeSize(node);
    node.size = result.size;
    node.lineCount = result.lineCount;

    _nodeLog.fine(
      'TOGGLING EXPANSION: $id oldExpanded=$oldExpanded -> newExpanded=$newExpanded, newSize=${node.size}',
    );

    final cmd = PatchNodeCommand(
      targetId: id,
      tableName: node.tableName,
      api: controller.syncEngine.api,
      controller: controller,
      oldSize: oldSize,
      newSize: node.size,
      oldExpanded: oldExpanded,
      newExpanded: newExpanded,
    );

    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.expansion,
        payload: newExpanded,
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
  }

  /// Updates the closed state of a ContainerUiNode and publishes the update event.
  void setContainerClosed(RawUuid id, bool isClosed) {
    final node = controller.store.nodeLookup[id];
    if (node is! ContainerUiNode) return;
    if (node.isClosed == isClosed) return;
    node.isClosed = isClosed;
    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: node.tableName,
        type: GraphUpdateType.expansion,
        payload: isClosed,
      ),
    );
    controller.relationEngine.onNodeMoved(id);
  }

  /// Converts an existing node (e.g. INode) to a ContainerUiNode.
  void convertNodeToContainer(RawUuid id) {
    final oldNode = controller.store.nodeLookup[id];
    if (oldNode == null || oldNode is ContainerUiNode) return;

    _nodeLog.info('Converting node $id (${oldNode.tableName}) to ContainerUiNode');

    final title = oldNode.content.toPlainText().trim();
    final containerTitle = title.isNotEmpty ? title : 'Container';

    final containerNode = ContainerUiNode(
      id: oldNode.id,
      position: oldNode.position,
      size: const Size(100.0, 80.0),
      layer: oldNode.layer,
      parentContainerId: oldNode.parentContainerId,
      title: containerTitle,
      isClosed: true,
      childCount: 0,
      tags: oldNode is InfoUiNode ? oldNode.tags : const [],
      comments: oldNode is InfoUiNode ? oldNode.comments : const [],
      style: oldNode.style ?? resolveStyle(oldNode),
      resolvedStyle: oldNode.resolvedStyle ?? resolveStyle(oldNode),
      locked: oldNode.locked,
      significance: oldNode.significance,
    );

    // 1. Delete old node from DB
    final deleteCmd = DeleteNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      tableName: oldNode.tableName,
      node: oldNode,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(deleteCmd, immediate: true);

    // 2. Insert new ContainerUiNode into store
    controller.store.nodeLookup[id] = containerNode;

    // 3. Adopt candidate nodes on canvas that fall within this container's bounds
    final containerRect = Rect.fromLTWH(
      containerNode.position.dx,
      containerNode.position.dy,
      containerNode.size.width,
      containerNode.size.height,
    );
    int adoptedCount = 0;
    for (final otherNode in controller.store.nodeLookup.values.toList()) {
      if (otherNode.id == id || otherNode.parentContainerId != null) continue;
      final otherCenter = otherNode.position + Offset(otherNode.size.width / 2, otherNode.size.height / 2);
      if (containerRect.contains(otherCenter)) {
        final oldWorldPos = otherNode.position;
        final localPos = oldWorldPos - containerNode.position;

        otherNode.parentContainerId = id;
        otherNode.position = localPos;

        controller.spatial.spatialIndex.migrateNodeSpatialGrid(otherNode.id, null, id, oldWorldPos, localPos, otherNode.size);

        adoptedCount++;
      }
    }
    containerNode.childCount = adoptedCount;

    controller.spatial.spatialIndex.insertNode(id, containerNode.parentContainerId, containerNode.position, containerNode.size);

    // Resolve style immediately for new container
    controller.styleUpdater?.updateStyleForNode(id);

    final createCmd = CreateNodeCommand(
      targetId: id,
      api: controller.syncEngine.api,
      node: containerNode,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(createCmd, immediate: true);

    controller.syncEngine.api.updateNodeCachePositions(
      positions: [
        (
          parseTypedRecordId(containerNode.tableName, id),
          containerNode.position.dx,
          containerNode.position.dy,
          containerNode.size.width,
          containerNode.size.height,
        ),
      ],
    );

    for (final rel in controller.store.relations) {
      if (rel.fromNodeId == id) {
        rel.fromNodeTable = containerNode.tableName;
      }
      if (rel.toNodeId == id) {
        rel.toNodeTable = containerNode.tableName;
      }
    }

    controller.relationEngine.onNodeMoved(id);

    controller.publishUpdate(
      GraphEntityUpdate(
        id: id,
        tableName: containerNode.tableName,
        type: GraphUpdateType.nodeAdded,
      ),
    );
    controller.triggerUpdate();
  }

  /// Creates a FrameUiNode enclosing the specified nodes with margin, or at a default position.
  RawUuid createFrameFromSelection(Iterable<RawUuid> nodeIds, {Offset? defaultPosition}) {
    final targetNodes = nodeIds
        .map((id) => controller.store.nodeLookup[id])
        .whereType<UiNode>()
        .toList();

    if (targetNodes.isEmpty) {
      return createNode(
        UiNodes.frame,
        defaultPosition ?? Offset.zero,
        size: const Size(400.0, 300.0),
      );
    }

    final parentScopeContainerId = targetNodes.first.parentContainerId;
    final scopedNodes = targetNodes
        .where((n) => n.parentContainerId == parentScopeContainerId)
        .toList();

    double minX = scopedNodes.first.position.dx;
    double minY = scopedNodes.first.position.dy;
    double maxX = scopedNodes.first.position.dx + scopedNodes.first.size.width;
    double maxY = scopedNodes.first.position.dy + scopedNodes.first.size.height;

    for (final n in scopedNodes.skip(1)) {
      if (n.position.dx < minX) minX = n.position.dx;
      if (n.position.dy < minY) minY = n.position.dy;
      final r = n.position.dx + n.size.width;
      final b = n.position.dy + n.size.height;
      if (r > maxX) maxX = r;
      if (b > maxY) maxY = b;
    }

    const margin = 28.0;
    final framePos = Offset(minX - margin, minY - margin - 20.0);
    final frameSize = Size((maxX - minX) + margin * 2, (maxY - minY) + margin * 2 + 20.0);

    return createNode(
      UiNodes.frame,
      framePos,
      parentContainerId: parentScopeContainerId,
      size: frameSize,
    );
  }

  /// Groups the specified nodes under a single logical groupId.
  RawUuid? groupNodes(Iterable<RawUuid> nodeIds) {
    final validNodes = nodeIds
        .map((id) => controller.store.nodeLookup[id])
        .whereType<UiNode>()
        .toList();
    if (validNodes.length < 2) return null;

    final newGroupId = RawUuid.v4();
    for (final node in validNodes) {
      node.groupId = newGroupId;
    }

    controller.triggerUpdate();
    return newGroupId;
  }

  /// Ungroups the specified nodes (or all nodes sharing their group IDs).
  void ungroupNodes(Iterable<RawUuid> nodeIds) {
    final targetNodes = nodeIds
        .map((id) => controller.store.nodeLookup[id])
        .whereType<UiNode>()
        .toList();

    final groupIdsToClear = targetNodes
        .map((n) => n.groupId)
        .whereType<RawUuid>()
        .toSet();

    if (groupIdsToClear.isEmpty) return;

    for (final node in controller.store.nodeLookup.values) {
      if (node.groupId != null && groupIdsToClear.contains(node.groupId)) {
        node.groupId = null;
      }
    }

    controller.triggerUpdate();
  }
}

