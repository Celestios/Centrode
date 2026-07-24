import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

final Logger _log = Logger('MoveNodeCommand');

class MoveNodeCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final String tableName;
  final GraphApi api;
  final GraphCommandContext controller;
  final Offset? oldPosition;
  final Offset? newPosition;
  final Size? oldSize;
  final Size? newSize;
  final NodeStyle? oldStyle;
  final NodeStyle? newStyle;
  final bool? oldExpanded;
  final bool? newExpanded;

  MoveNodeCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    required this.controller,
    this.oldPosition,
    this.newPosition,
    this.oldSize,
    this.newSize,
    this.oldStyle,
    this.newStyle,
    this.oldExpanded,
    this.newExpanded,
  });

  @override
  CommandCategory get category => CommandCategory.spatial;

  @override
  Future<void> execute() async {
    _log.info('execute MoveNode key=$targetId table=$tableName');
    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    if (newPosition != null && oldPosition != null) {
      forwardPatches.add(
        NodePatch.position(
          frb.Coordinates(
            x: newPosition!.dx.round(),
            y: newPosition!.dy.round(),
          ),
        ),
      );
      reversePatches.add(
        NodePatch.position(
          frb.Coordinates(
            x: oldPosition!.dx.round(),
            y: oldPosition!.dy.round(),
          ),
        ),
      );
    }
    if (newSize != null && oldSize != null) {
      forwardPatches.add(
        NodePatch.size(
          frb.Size(
            width: newSize!.width.round(),
            height: newSize!.height.round(),
          ),
        ),
      );
      reversePatches.add(
        NodePatch.size(
          frb.Size(
            width: oldSize!.width.round(),
            height: oldSize!.height.round(),
          ),
        ),
      );
    }
    if (newStyle != null || oldStyle != null) {
      final currentStyle = controller.store.nodeLookup[targetId]?.style;
      forwardPatches.add(NodePatch.style(currentStyle ?? newStyle));
      reversePatches.add(NodePatch.style(oldStyle));
    }
    if (newExpanded != null && oldExpanded != null) {
      forwardPatches.add(NodePatch.isExpanded(newExpanded!));
      reversePatches.add(NodePatch.isExpanded(oldExpanded!));
    }

    _log.fine('execute patches=${forwardPatches.length} position=$newPosition size=$newSize');

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: parseTypedRecordId(tableName, targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
    if (newPosition != null) {
      controller.spatial.saveConfirmedPosition(targetId, newPosition!);
    }
  }

  @override
  void undo() {
    _log.info('undo MoveNode key=$targetId');
    final node = controller.store.nodeLookup[targetId];
    if (node != null) {
      if (oldPosition != null && newPosition != null) {
        node.position = oldPosition!;
        controller.spatial.spatialGrid.update(
          targetId,
          newPosition!,
          oldPosition!,
        );
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: tableName,
            type: GraphUpdateType.position,
            payload: oldPosition,
          ),
        );
      }
      if (oldSize != null) {
        node.size = oldSize!;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: tableName,
            type: GraphUpdateType.size,
            payload: oldSize,
          ),
        );
      }
      if (oldStyle != null) {
        node.style = oldStyle;
      }
      if (oldExpanded != null) {
        node.isExpanded = oldExpanded!;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: tableName,
            type: GraphUpdateType.expansion,
            payload: oldExpanded,
          ),
        );
      }
      controller.triggerUpdate();
    }
  }
}
