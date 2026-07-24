import 'dart:async';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/entity.dart';
import 'package:mycelium/src/rust/domain/id.dart';
import 'package:mycelium/src/rust/domain/relations.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/tags.dart';
import 'package:mycelium/src/rust/domain/theme.dart';
import 'package:mycelium/src/rust/domain/templates.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/base_models.dart';
import 'package:mycelium/src/rust/persistence/history.dart';
import 'package:mycelium/src/rust/domain/snapshot.dart';
import 'package:mycelium/src/rust/bridge/stream.dart';

/// Decoupled interface for the Rust FFI surface.
abstract class GraphApi {
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation});
  Future<void> close();
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<String>? relationIds,
  });
  Future<ComputedRelation> computeSingleRelation({
    required RelationEngineConfig config,
    required String edgeId,
    required String fromNodeId,
    required String toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    RoutingMode? routingMode,
    double? overrideStartX,
    double? overrideStartY,
    double? overrideEndX,
    double? overrideEndY,
  });
  Stream<GraphEvent> createGraphStream();
  Future<void> createNode({required Nodes input});
  Future<void> createRelation({required IRelation input});
  Future<void> createTag({required Tag tag});
  Future<void> createTheme({required String key, required ThemeFields fields});
  Future<void> deleteNodeEntry({required String table, required String key});
  Future<void> deleteRelation({required String table, required String key});
  Future<void> deleteTag({required String key});
  Future<void> deleteTemplate({required String key});
  Future<String?> getActiveThemeId();
  Future<List<Tag>> getAllTags();
  Future<List<Template>> getAllTemplates();
  Future<List<Theme>> getAllThemes();
  Future<GraphSnapshot> getGraphSnapshot();
  Future<Nodes?> getNode({required String table, required String key});
  Future<Tag?> getTag({required String key});
  Future<Theme?> getTheme({required String key});
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  });
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  });
  Future<List<Nodes>> querySearch({required String query});
  Future<HistoryRecord?> redo();
  Future<int> redoCount();
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  });
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  });
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  });
  Future<void> setActiveTheme({required String themeKey});
  Future<void> setActiveThemeId({required String themeId});
  Future<HistoryRecord?> undo();
  Future<int> undoCount();
  Future<void> updateNode({required Nodes input});
  Future<void> updateNodeCachePositions({
    required List<(String, double, double, double, double)> positions,
  });
  Future<void> updateRelation({required IRelation input});
  Future<void> updateTag({required Tag tag});
  Future<void> updateTheme({required Theme theme});
  Future<void> updateViewportState({required ViewportState state});
}

/// Concrete FFI-backed implementation of [GraphApi] wrapping [AppHandle].
class RustAppHandleWrapper implements GraphApi {
  final AppHandle _api;

  RustAppHandleWrapper(this._api);

  @override
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation}) =>
      _api.applyEntityMutation(mutation: mutation);

  @override
  Future<void> close() => _api.close();

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<String>? relationIds,
  }) =>
      _api.computeRelations(config: config, relationIds: relationIds);

  @override
  Future<ComputedRelation> computeSingleRelation({
    required RelationEngineConfig config,
    required String edgeId,
    required String fromNodeId,
    required String toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    RoutingMode? routingMode,
    double? overrideStartX,
    double? overrideStartY,
    double? overrideEndX,
    double? overrideEndY,
  }) =>
      _api.computeSingleRelation(
        config: config,
        edgeId: edgeId,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        fromSide: fromSide,
        toSide: toSide,
        routingMode: routingMode,
        overrideStartX: overrideStartX,
        overrideStartY: overrideStartY,
        overrideEndX: overrideEndX,
        overrideEndY: overrideEndY,
      );

  @override
  Stream<GraphEvent> createGraphStream() => _api.createGraphStream();

  @override
  Future<void> createNode({required Nodes input}) =>
      _api.createNode(input: input);

  @override
  Future<void> createRelation({required IRelation input}) =>
      _api.createRelation(input: input);

  @override
  Future<void> createTag({required Tag tag}) => _api.createTag(tag: tag);

  @override
  Future<void> createTheme({required String key, required ThemeFields fields}) =>
      _api.createTheme(key: key, fields: fields);

  @override
  Future<void> deleteNodeEntry({required String table, required String key}) =>
      _api.deleteNodeEntry(id: TypedRecordId(kind: TableKind.values.byName(table), key: UuidValue.fromString(key)));

  @override
  Future<void> deleteRelation({required String table, required String key}) =>
      _api.deleteRelation(id: TypedRecordId(kind: TableKind.values.byName(table), key: UuidValue.fromString(key)));

  @override
  Future<void> deleteTag({required String key}) => _api.deleteTag(key: key);

  @override
  Future<void> deleteTemplate({required String key}) =>
      _api.deleteTemplate(key: key);

  @override
  Future<String?> getActiveThemeId() => _api.getActiveThemeId();

  @override
  Future<List<Tag>> getAllTags() => _api.getAllTags();

  @override
  Future<List<Template>> getAllTemplates() => _api.getAllTemplates();

  @override
  Future<List<Theme>> getAllThemes() => _api.getAllThemes();

  @override
  Future<GraphSnapshot> getGraphSnapshot() => _api.getGraphSnapshot();

  @override
  Future<Nodes?> getNode({required String table, required String key}) =>
      _api.getNode(id: TypedRecordId(kind: TableKind.values.byName(table), key: UuidValue.fromString(key)));

  @override
  Future<Tag?> getTag({required String key}) => _api.getTag(key: key);

  @override
  Future<Theme?> getTheme({required String key}) => _api.getTheme(key: key);

  @override
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  }) =>
      _api.instantiateTemplate(key: key, targetX: targetX, targetY: targetY);

  @override
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  }) =>
      _api.loadMapFromFile(filePath: filePath, attachmentDir: attachmentDir);

  @override
  Future<List<Nodes>> querySearch({required String query}) =>
      _api.querySearch(query: query);

  @override
  Future<HistoryRecord?> redo() => _api.redo();

  @override
  Future<int> redoCount() => _api.redoCount();

  @override
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  }) =>
      _api.rerouteRelation(record: record, from: from, to: to);

  @override
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  }) =>
      _api.saveMapToFile(filePath: filePath, attachmentDir: attachmentDir);

  @override
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  }) =>
      _api.saveTemplateFromSelection(
        name: name,
        nodeKeys: nodeKeys,
        relationKeys: relationKeys,
      );

  @override
  Future<void> setActiveTheme({required String themeKey}) =>
      _api.setActiveTheme(themeKey: themeKey);

  @override
  Future<void> setActiveThemeId({required String themeId}) =>
      _api.setActiveThemeId(themeId: themeId);

  @override
  Future<HistoryRecord?> undo() => _api.undo();

  @override
  Future<int> undoCount() => _api.undoCount();

  @override
  Future<void> updateNode({required Nodes input}) =>
      _api.updateNode(input: input);

  @override
  Future<void> updateNodeCachePositions({
    required List<(TypedRecordId, double, double, double, double)> positions,
  }) =>
      _api.updateNodeCachePositions(positions: positions);

  @override
  Future<void> updateRelation({required IRelation input}) =>
      _api.updateRelation(input: input);

  @override
  Future<void> updateTag({required Tag tag}) => _api.updateTag(tag: tag);

  @override
  Future<void> updateTheme({required Theme theme}) =>
      _api.updateTheme(theme: theme);

  @override
  Future<void> updateViewportState({required ViewportState state}) =>
      _api.updateViewportState(state: state);
}
