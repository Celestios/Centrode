import 'dart:ui';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_query.dart';
import 'base.dart';
import 'graph_command_context.dart';

class UpdateNodeStyleCommand extends GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final NodeStyle? oldStyle;
  final NodeStyle? newStyle;
  final Size? oldSize;
  final Size? newSize;
  final GraphCommandContext controller;

  UpdateNodeStyleCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldStyle,
    this.newStyle,
    this.oldSize,
    this.newSize,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    if (newStyle != null || oldStyle != null) {
      forwardPatches.add(NodePatch.style(newStyle));
      reversePatches.add(NodePatch.style(oldStyle));
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

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: frb.RecordStrings(table: tableName, key: targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
  }

  @override
  void undo() {
    final node = controller.store.nodeLookup[targetId];
    if (node != null) {
      node.style = oldStyle;
      if (oldSize != null) {
        node.size = oldSize!;
      }
      controller.styleUpdater?.updateStyleForNode(targetId);
      controller.publishUpdate(
        GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.style,
          payload: oldStyle,
        ),
      );
      if (oldSize != null) {
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: tableName,
            type: GraphUpdateType.size,
            payload: oldSize,
          ),
        );
      }
      controller.triggerUpdate();
    }
  }
}
