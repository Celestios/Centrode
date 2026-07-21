import 'package:mycelium/shared/logging.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('InstantiateTemplateCommand');

class InstantiateTemplateCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
  final double targetX;
  final double targetY;
  final GraphCommandContext controller;

  InstantiateTemplateCommand({
    required this.targetId,
    required this.api,
    required this.targetX,
    required this.targetY,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute InstantiateTemplate key=$targetId pos=($targetX, $targetY)');
    await api.instantiateTemplate(
      key: targetId,
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
