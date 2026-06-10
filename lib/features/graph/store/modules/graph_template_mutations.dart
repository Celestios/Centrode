import 'dart:ui' show Offset;
import 'package:mycelium/src/rust/domain/base_models.dart' show RecordStrings;
import '../../models/models.dart';
import '../graph_data_controller.dart';

class GraphTemplateMutations {
  final GraphDataController controller;

  GraphTemplateMutations(this.controller);

  Future<List<Template>> getAllTemplates() async {
    final dynamic api = controller.syncEngine.api;
    final List<dynamic> raw = await api.getAllTemplates();
    return raw.cast<Template>();
  }

  Future<void> saveTemplateFromSelection(
    String name,
    List<String> nodeIds,
    List<String> relationIds,
  ) async {
    final dynamic api = controller.syncEngine.api;
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

    await api.saveTemplateFromSelection(
      name: name,
      nodeKeys: nodeRecords,
      relationKeys: relationRecords,
    );
    controller.triggerUpdate();
  }

  Future<void> instantiateTemplate(String key, Offset canvasCoords) async {
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
    final dynamic api = controller.syncEngine.api;
    await api.deleteTemplate(key: key);
    controller.triggerUpdate();
  }
}
