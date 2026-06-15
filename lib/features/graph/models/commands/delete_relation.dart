import 'package:mycelium/src/rust/bridge/api.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';
import 'graph_command_context.dart';

class DeleteRelationCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final String tableName;
  final UiRelation relation;
  final GraphCommandContext controller;

  DeleteRelationCommand({
    required this.targetId,
    required this.api,
    required this.tableName,
    required this.relation,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.deleteRelation(table: tableName, key: targetId);
  }

  @override
  void undo() {
    controller.store.relationLookup[targetId] = relation;
    controller.publishUpdate(
      GraphEntityUpdate(
        id: targetId,
        tableName: tableName,
        type: GraphUpdateType.relationAdded,
        payload: relation,
      ),
    );
    controller.triggerUpdate();
  }
}
