import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_query.dart';
import '../graph_node.dart';
import 'base.dart';
import 'graph_command_context.dart';

class UpdateCommentsCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiNode node;
  final List<frb.Comment> oldComments;
  final GraphCommandContext controller;

  UpdateCommentsCommand({
    required this.targetId,
    required this.api,
    required this.node,
    required this.oldComments,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    await api.updateNode(input: node.toRust());
  }

  @override
  void undo() {
    final node = controller.store.nodeLookup[targetId];
    if (node is InfoUiNode) {
      node.comments = oldComments;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: targetId,
          tableName: node.tableName,
          type: GraphUpdateType.comments,
          payload: oldComments,
        ),
      );
      controller.triggerUpdate();
    }
  }
}
