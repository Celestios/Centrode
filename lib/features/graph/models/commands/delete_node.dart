import 'package:mycelium/shared/logging.dart';
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import '../models.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';

final Logger _log = Logger('DeleteNodeCommand');

/// Command for deleting a node with rollback support.
/// Captures the node data for restoration on FFI failure.
class DeleteNodeCommand extends GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final GraphApi api;
  final String tableName;
  final UiNode node;
  final GraphCommandContext controller;

  DeleteNodeCommand({
    required this.targetId,
    required this.api,
    required this.tableName,
    required this.node,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute DeleteNode key=$targetId table=$tableName');
    await api.deleteNodeEntry(id: parseTypedRecordId(tableName, targetId));
  }

  @override
  void undo() {
    _log.info('undo DeleteNode key=$targetId restoring node');
    controller.store.nodeLookup[targetId] = node;
    controller.spatial.spatialGrid.insert(targetId, node.position);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: targetId,
        tableName: tableName,
        type: GraphUpdateType.nodeAdded,
      ),
    );
    controller.triggerUpdate();
  }
}
