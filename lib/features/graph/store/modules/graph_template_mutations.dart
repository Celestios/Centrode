import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/templates.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show RecordStrings;
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
    final dynamic api = controller.syncEngine.api;
    await api.instantiateTemplate(
      key: key,
      targetX: canvasCoords.dx,
      targetY: canvasCoords.dy,
    );
    await controller.loadGraph();
  }

  Future<void> deleteTemplate(String key) async {
    final dynamic api = controller.syncEngine.api;
    await api.deleteTemplate(key: key);
    controller.triggerUpdate();
  }
}
