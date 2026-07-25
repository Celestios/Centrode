import 'package:mycelium/shared/logging.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

final Logger _log = Logger('InstantiateTemplateCommand');

class InstantiateTemplateCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final GraphApi api;
  final double targetX;
  final double targetY;
  final GraphCommandContext controller;
  final String templateKey;

  InstantiateTemplateCommand({
    required this.targetId,
    required this.api,
    required this.targetX,
    required this.targetY,
    required this.controller,
    required this.templateKey,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  bool get isUndoable => false;

  @override
  Future<void> execute() async {
    _log.info('execute InstantiateTemplate key=$templateKey pos=($targetX, $targetY)');
    await api.instantiateTemplate(
      key: templateKey,
      targetX: targetX,
      targetY: targetY,
    );
  }

  @override
  void undo() {
    // Rollback handled externally or no-op on FFI failure before commit.
  }

  @override
  void onSuccess() {
    _log.info('onSuccess InstantiateTemplate key=$targetId, reloading graph');
    controller.loadGraph();
  }
}
