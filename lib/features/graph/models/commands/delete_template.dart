import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/templates.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('DeleteTemplateCommand');

class DeleteTemplateCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
  final Template template;
  final GraphCommandContext controller;

  DeleteTemplateCommand({
    required this.targetId,
    required this.api,
    required this.template,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute DeleteTemplate key=$targetId');
    await api.deleteTemplate(key: targetId);
  }

  @override
  void undo() {
    _log.info('undo DeleteTemplate key=$targetId');
    // Restoration of deleted templates is currently a noop since FFI does not expose direct template insertion.
  }

  @override
  void onSuccess() {
    controller.triggerUpdate();
  }
}
