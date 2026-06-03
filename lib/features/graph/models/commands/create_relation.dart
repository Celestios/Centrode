import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';

final _log = Logger('CreateRelationCommand');

class CreateRelationCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiRelation relation;
  final GraphDataController controller;

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

