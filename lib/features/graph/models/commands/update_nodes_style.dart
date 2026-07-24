import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:mycelium/src/rust/domain/patches.dart';
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

final Logger _log = Logger('UpdateNodesStyleCommand');

class UpdateNodesStyleCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final GraphApi api;
  final Map<RawUuid, NodeStyle> oldStyles;
  final Map<RawUuid, NodeStyle> newStyles;
  final Map<RawUuid, Size> oldSizes;
  final Map<RawUuid, Size> newSizes;
  final GraphCommandContext controller;

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
    _log.info('execute UpdateNodesStyle count=${newStyles.length}');
    for (final id in newStyles.keys) {
      final (forwardPatches, reversePatches) = buildNodeStylePatches(
        oldStyles[id], newStyles[id], oldSizes[id], newSizes[id],
      );

      if (forwardPatches.isNotEmpty) {
        final node = controller.store.nodeLookup[id];
        final tableName = node?.tableName ?? 'INode';
        final patch = SymmetricEntityPatch(
          id: parseTypedRecordId(tableName, id),
          forward: EntityPatch.node(forwardPatches),
          reverse: EntityPatch.node(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateNodesStyle count=${oldStyles.length}');
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
