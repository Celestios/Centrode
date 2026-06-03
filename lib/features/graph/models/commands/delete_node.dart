import 'package:mycelium/src/rust/bridge/api.dart';
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import '../models.dart';

/// Command for deleting a node with rollback support.
/// Captures the node data for restoration on FFI failure.
class DeleteNodeCommand extends GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final AppHandle api;
  final String tableName;
  final UiNode node;
  final GraphDataController controller;

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
    await api.deleteNodeEntry(table: tableName, key: targetId);
  }

  @override
  void undo() {
    controller.store.nodeLookup[targetId] = node;
    controller.spatial.spatialGrid.insert(targetId, node.position);
    controller.publishUpdate(GraphEntityUpdate(
      id: targetId,
      tableName: tableName,
      type: GraphUpdateType.nodeAdded,
    ));
    controller.triggerUpdate();
  }
}

