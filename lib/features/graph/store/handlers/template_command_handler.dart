import 'dart:ui' show Offset;
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/src/rust/domain/templates.dart';
import 'package:centrode/src/rust/domain/id.dart';
import '../../models/commands/patch_helpers.dart';
import '../../models/commands/save_template.dart';
import '../../models/commands/delete_template.dart';
import '../../models/commands/instantiate_template.dart';
import '../../models/commands/graph_command_context.dart';
import '../api/template_api.dart';
import '../command_processor.dart';

/// Command handler managing template storage, saving from selection, and instantiation.
class TemplateCommandHandler {
  final Logger _log = Logger('TemplateCommandHandler');
  final TemplateApi _api;
  final GraphCommandContext _context;
  final CommandProcessor _processor;

  TemplateCommandHandler({
    required TemplateApi api,
    required GraphCommandContext context,
    required CommandProcessor processor,
  })  : _api = api,
        _context = context,
        _processor = processor;

  Future<List<Template>> getAllTemplates() async {
    _log.info('getAllTemplates called');
    return await _api.getAllTemplates();
  }

  Future<void> saveTemplateFromSelection(
    String name,
    List<RawUuid> nodeIds,
    List<RawUuid> relationIds,
  ) async {
    _log.info(
      'saveTemplateFromSelection name=$name nodes=${nodeIds.length} relations=${relationIds.length}',
    );
    final List<TypedRecordId> nodeRecords = nodeIds.map((id) {
      final node = _context.store.nodeLookup[id];
      final table = node?.tableName ?? 'INode';
      return parseTypedRecordId(table, id);
    }).toList();
    final List<TypedRecordId> relationRecords = relationIds.map((id) {
      return parseTypedRecordId('IRelation', id);
    }).toList();

    final cmd = SaveTemplateCommand(
      targetId: RawUuid.v4(),
      api: _api,
      name: name,
      nodeKeys: nodeRecords,
      relationKeys: relationRecords,
      controller: _context,
    );
    _processor.queueCommand(cmd, immediate: true);
  }

  Future<void> instantiateTemplate(String key, Offset canvasCoords) async {
    _log.info(
      'instantiateTemplate key=$key pos=(${canvasCoords.dx}, ${canvasCoords.dy})',
    );
    final cmd = InstantiateTemplateCommand(
      targetId: RawUuid.fromString(key),
      api: _api,
      targetX: canvasCoords.dx,
      targetY: canvasCoords.dy,
      controller: _context,
      templateKey: key,
    );
    _processor.queueCommand(cmd, immediate: true);
  }

  Future<void> deleteTemplate(String key) async {
    _log.info('deleteTemplate key=$key');
    final templates = await getAllTemplates();
    final template = templates.firstWhere((t) => t.key.key.uuid == key);
    final cmd = DeleteTemplateCommand(
      targetId: RawUuid.fromString(key),
      api: _api,
      template: template,
      controller: _context,
      templateKey: key,
    );
    _processor.queueCommand(cmd, immediate: true);
  }
}
