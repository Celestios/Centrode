import 'package:mycelium/src/rust/bridge/api.dart';
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import '../graph_node.dart';
import 'base.dart';

class CreateNodeCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiNode node;
  final GraphDataController controller;

  CreateNodeCommand({
    required this.targetId,
    required this.api,
    required this.node,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.createNode(input: node.toRust());
  }

  @override
  void undo() {
    controller.store.nodeLookup.remove(targetId);
    controller.spatial.spatialGrid.remove(targetId, node.position);
    controller.spatial.clearConfirmedPosition(targetId);
    controller.publishUpdate(GraphEntityUpdate(
      id: targetId,
      tableName: node.tableName,
      type: GraphUpdateType.nodeDeleted,
    ));
    controller.triggerUpdate();
  }
}

