import 'package:mycelium/shared/logging.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('DeleteRelationCommand');

class DeleteRelationCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
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
    _log.info('execute DeleteRelation key=$targetId table=$tableName');
    await api.deleteRelation(table: tableName, key: targetId);
  }

  @override
  void undo() {
    _log.info('undo DeleteRelation key=$targetId');
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
