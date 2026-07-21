import 'package:mycelium/shared/logging.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final _log = Logger('CreateRelationCommand');

class CreateRelationCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
  final UiRelation relation;
  final GraphCommandContext controller;

  CreateRelationCommand({
    required this.targetId,
    required this.api,
    required this.relation,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    try {
      _log.info('Executing CreateRelationCommand for $targetId');
      await api.createRelation(input: relation.toRust());
      _log.info('Calling reloadGraph...');
      await controller.loadGraph();
      _log.info('Executed CreateRelationCommand successfully.');
    } catch (e, st) {
      _log.severe('CreateRelationCommand FAILED: $e', e, st);
      rethrow;
    }
  }

  @override
  void undo() {
    controller.store.relationLookup.remove(relation.id);
    controller.publishUpdate(
      GraphEntityUpdate(
        id: relation.id,
        tableName: 'IRelation',
        type: GraphUpdateType.relationDeleted,
      ),
    );
    controller.triggerUpdate();
  }
}
