import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show RecordStrings;
import '../../store/graph_api.dart';
import 'base.dart';
import 'graph_command_context.dart';

final Logger _log = Logger('SaveTemplateCommand');

class SaveTemplateCommand extends GraphCommand {
  @override
  final String targetId;
  final GraphApi api;
  final String name;
  final List<RecordStrings> nodeKeys;
  final List<RecordStrings> relationKeys;
  final GraphCommandContext controller;

  SaveTemplateCommand({
    required this.targetId,
    required this.api,
    required this.name,
    required this.nodeKeys,
    required this.relationKeys,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    _log.info('execute SaveTemplate name=$name');
    await api.saveTemplateFromSelection(
      name: name,
      nodeKeys: nodeKeys,
      relationKeys: relationKeys,
    );
  }

  @override
  void undo() {
    _log.info('undo SaveTemplate name=$name');
    api.deleteTemplate(key: name);
  }

  @override
  void onSuccess() {
    controller.triggerUpdate();
  }
}
