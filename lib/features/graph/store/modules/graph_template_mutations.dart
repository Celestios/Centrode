import 'dart:ui' show Offset;
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show RecordStrings;
import '../../models/models.dart';
import '../../models/commands/save_template.dart';
import '../../models/commands/delete_template.dart';
import '../command_queue_processor.dart';

class GraphTemplateMutations {
  final Logger _log = Logger('GraphTemplateMutations');
  final CommandQueueProcessor controller;

  GraphTemplateMutations(this.controller);

  Future<List<Template>> getAllTemplates() async {
    _log.info('getAllTemplates called');
    final api = controller.syncEngine.api;
    final List<Template> raw = await api.getAllTemplates();
    return raw;
  }

  Future<void> saveTemplateFromSelection(
    String name,
    List<String> nodeIds,
    List<String> relationIds,
  ) async {
    _log.info('saveTemplateFromSelection name=$name nodes=${nodeIds.length} relations=${relationIds.length}');
    final api = controller.syncEngine.api;
    final nodeRecords = nodeIds.map((id) {
      final node = controller.store.nodeLookup[id];
      final table =
          node?.tableName ?? (id.contains(':') ? id.split(':').first : 'INode');
      final key = id.contains(':') ? id.split(':').last : id;
      return RecordStrings(table: table, key: key);
    }).toList();
    final relationRecords = relationIds.map((id) {
      final table = id.contains(':') ? id.split(':').first : 'IRelation';
      final key = id.contains(':') ? id.split(':').last : id;
      return RecordStrings(table: table, key: key);
    }).toList();

    final cmd = SaveTemplateCommand(
      targetId: name,
      api: api,
      name: name,
      nodeKeys: nodeRecords,
      relationKeys: relationRecords,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
  }

  Future<void> instantiateTemplate(String key, Offset canvasCoords) async {
    _log.info('instantiateTemplate key=$key pos=(${canvasCoords.dx}, ${canvasCoords.dy})');
    final cmd = InstantiateTemplateCommand(
      targetId: key,
      api: controller.syncEngine.api,
      targetX: canvasCoords.dx,
      targetY: canvasCoords.dy,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
  }

  Future<void> deleteTemplate(String key) async {
    _log.info('deleteTemplate key=$key');
    final api = controller.syncEngine.api;
    final templates = await getAllTemplates();
    final template = templates.firstWhere((t) => t.key == key);
    final cmd = DeleteTemplateCommand(
      targetId: key,
      api: api,
      template: template,
      controller: controller,
    );
    controller.syncEngine.processor.queueCommand(cmd, immediate: true);
  }
}
