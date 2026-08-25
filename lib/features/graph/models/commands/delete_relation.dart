import 'package:centrode/shared/logging.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('DeleteRelationCommand');

class DeleteRelationCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final RelationApi api;
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
    await api.deleteRelation(id: parseTypedRecordId(tableName, targetId));
  }

  @override
  void undo() {
    _log.info('undo DeleteRelation key=$targetId');
    restoreDeletedEntity(
      controller: controller,
      targetId: targetId,
      tableName: tableName,
      lookupMap: controller.store.relationLookup,
      entity: relation,
      updateType: GraphUpdateType.relationAdded,
      payload: relation,
    );
  }
}
