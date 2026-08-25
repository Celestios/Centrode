import 'package:centrode/shared/logging.dart';
import 'package:centrode/src/rust/domain/types.dart';
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('DeleteTagCommand');

class DeleteTagCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final TagApi api;
  final Tag tag;
  final GraphCommandContext controller;

  DeleteTagCommand({
    required this.targetId,
    required this.api,
    required this.tag,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute DeleteTag key=$targetId');
    await api.deleteTag(key: targetId.toUuidString());
  }

  @override
  void undo() {
    _log.info('undo DeleteTag key=$targetId');
    api.createTag(tag: tag);
  }

  @override
  void onSuccess() {
    controller.triggerUpdate();
  }
}
