import 'dart:ui';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';

class UpdateNodesStyleCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final Map<String, NodeStyle> oldStyles;
  final Map<String, NodeStyle> newStyles;
  final Map<String, Size> oldSizes;
  final Map<String, Size> newSizes;
  final GraphDataController controller;

  UpdateNodesStyleCommand({
    required this.targetId,
    required this.api,
    required this.oldStyles,
    required this.newStyles,
    required this.oldSizes,
    required this.newSizes,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    for (final id in newStyles.keys) {
      final newStyle = newStyles[id];
      final oldStyle = oldStyles[id];
      final newSize = newSizes[id];
      final oldSize = oldSizes[id];

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
              width: newSize.width.round(),
              height: newSize.height.round(),
            ),
          ),
        );
        reversePatches.add(
          NodePatch.size(
            frb.Size(
              width: oldSize.width.round(),
              height: oldSize.height.round(),
            ),
          ),
        );
      }

      if (forwardPatches.isNotEmpty) {
        final node = controller.store.nodeLookup[id];
        final tableName = node?.tableName ?? 'INode';
        final patch = SymmetricEntityPatch(
          id: frb.RecordStrings(table: tableName, key: id),
          forward: EntityPatch.node(forwardPatches),
          reverse: EntityPatch.node(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
    for (final id in oldStyles.keys) {
      final node = controller.store.nodeLookup[id];
      if (node != null) {
        final oldStyle = oldStyles[id];
        final oldSize = oldSizes[id];
        node.style = oldStyle;
        if (oldSize != null) {
          node.size = oldSize;
        }
        controller.styleUpdater?.updateStyleForNode(id);
        controller.publishUpdate(
          GraphEntityUpdate(
            id: id,
            tableName: node.tableName,
            type: GraphUpdateType.style,
            payload: oldStyle,
          ),
        );
        if (oldSize != null) {
          controller.publishUpdate(
            GraphEntityUpdate(
              id: id,
              tableName: node.tableName,
              type: GraphUpdateType.size,
              payload: oldSize,
            ),
          );
        }
      }
    }
    controller.triggerUpdate();
  }
}
