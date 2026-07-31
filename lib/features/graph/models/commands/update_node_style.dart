import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/patches.dart';
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('UpdateNodeStyleCommand');

class UpdateNodeStyleCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final String tableName;
  final GraphApi api;
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
    _log.info('execute UpdateNodeStyle key=$targetId table=$tableName');
    final (forwardPatches, reversePatches) = buildNodeStylePatches(
      oldStyle,
      newStyle,
      oldSize,
      newSize,
    );

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: parseTypedRecordId(tableName, targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateNodeStyle key=$targetId');
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
