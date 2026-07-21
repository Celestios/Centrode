import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/tags.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('UpdateTagCommand');

class UpdateTagCommand extends GraphCommand {
  @override
  String targetId;
  final GraphApi api;
  final Tag oldTag;
  final Tag newTag;
  final GraphCommandContext controller;

  UpdateTagCommand({
    required this.targetId,
    required this.api,
    required this.oldTag,
    required this.newTag,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    _log.info('execute UpdateTag key=$targetId');
    await api.updateTag(tag: newTag);
  }

  @override
  void undo() {
    _log.info('undo UpdateTag key=$targetId');
    api.updateTag(tag: oldTag);
  }

  @override
  void onSuccess() {
    controller.triggerUpdate();
  }
}
