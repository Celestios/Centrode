import 'dart:ui';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';

class MoveNodeCommand extends GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final GraphDataController controller;
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
      forwardPatches.add(NodePatch.style(newStyle));
      reversePatches.add(NodePatch.style(oldStyle));
    }
    if (newExpanded != null && oldExpanded != null) {
      forwardPatches.add(NodePatch.isExpanded(newExpanded!));
      reversePatches.add(NodePatch.isExpanded(oldExpanded!));
    }

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: frb.RecordStrings(table: tableName, key: targetId),
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
    final node = controller.store.nodeLookup[targetId];
    if (node != null) {
      if (oldPosition != null && newPosition != null) {
        node.position = oldPosition!;
        controller.spatial.spatialGrid.update(targetId, newPosition!, oldPosition!);
        controller.publishUpdate(GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.position,
          payload: oldPosition,
        ));
      }
      if (oldSize != null) {
        node.size = oldSize!;
        controller.publishUpdate(GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.size,
          payload: oldSize,
        ));
      }
      if (oldStyle != null) {
        node.style = oldStyle;
      }
      if (oldExpanded != null) {
        node.isExpanded = oldExpanded!;
        controller.publishUpdate(GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.expansion,
          payload: oldExpanded,
        ));
      }
      controller.triggerUpdate();
    }
  }
}

