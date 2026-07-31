import 'package:centrode/shared/logging.dart';
import 'package:centrode/src/rust/domain/types.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('CreateTagCommand');

class CreateTagCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final GraphApi api;
  final Tag tag;
  final GraphCommandContext controller;

  CreateTagCommand({
    required this.targetId,
    required this.api,
    required this.tag,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute CreateTag key=$targetId');
    await api.createTag(tag: tag);
  }

  @override
  void undo() {
    _log.info('undo CreateTag key=$targetId');
    api.deleteTag(key: targetId.toUuidString());
  }

  @override
  void onSuccess() {
    controller.triggerUpdate();
  }
}
