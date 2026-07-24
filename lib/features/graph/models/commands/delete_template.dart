import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/types.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

final Logger _log = Logger('DeleteTemplateCommand');

class DeleteTemplateCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final GraphApi api;
  final Template template;
  final GraphCommandContext controller;
  final String templateKey;

  DeleteTemplateCommand({
    required this.targetId,
    required this.api,
    required this.template,
    required this.controller,
    required this.templateKey,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute DeleteTemplate key=$templateKey');
    await api.deleteTemplate(key: templateKey);
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
