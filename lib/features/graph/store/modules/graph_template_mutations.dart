import 'dart:ui' show Offset;
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/id.dart';
import '../../models/commands/patch_helpers.dart';
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
    final List<TypedRecordId> nodeRecords = nodeIds.map((id) {
      final node = controller.store.nodeLookup[id];
      final table =
          node?.tableName ?? (id.contains(':') ? id.split(':').first : 'INode');
      final key = id.contains(':') ? id.split(':').last : id;
      return parseTypedRecordId(table, key);
    }).toList();
    final List<TypedRecordId> relationRecords = relationIds.map((id) {
      final table = id.contains(':') ? id.split(':').first : 'IRelation';
      final key = id.contains(':') ? id.split(':').last : id;
      return parseTypedRecordId(table, key);
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
