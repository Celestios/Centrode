import 'package:mycelium/shared/logging.dart';
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import '../graph_node.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('CreateNodeCommand');

class CreateNodeCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
  final UiNode node;
  final GraphCommandContext controller;

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
    _log.info('execute CreateNode key=$targetId table=${node.tableName}');
    await api.createNode(input: node.toRust());
  }

  @override
  void undo() {
    _log.info('undo CreateNode key=$targetId');
    controller.store.nodeLookup.remove(targetId);
    controller.spatial.spatialGrid.remove(targetId, node.position);
    controller.spatial.clearConfirmedPosition(targetId);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: targetId,
        tableName: node.tableName,
        type: GraphUpdateType.nodeDeleted,
      ),
    );
    controller.triggerUpdate();
  }
}
