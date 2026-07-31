import 'dart:async';
import 'package:centrode/src/rust/bridge/api.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/persistence/history.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';
import 'package:centrode/src/rust/bridge/stream.dart';
import 'package:centrode/src/rust/domain/theme.dart';

/// Decoupled interface for the Rust FFI surface.
abstract class GraphApi {
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation});
  Future<void> close();
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<TypedRecordId>? relationIds,
  });
  Future<ComputedRelation> computeSingleRelation({
    required RelationEngineConfig config,
    required TypedRecordId edgeId,
    required TypedRecordId fromNodeId,
    required TypedRecordId toNodeId,
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
  Future<void> deleteNodeEntry({required TypedRecordId id});
  Future<void> deleteRelation({required TypedRecordId id});
  Future<void> deleteTag({required String key});
  Future<void> deleteTemplate({required String key});
  Future<String?> getActiveThemeId();
  Future<List<Tag>> getAllTags();
  Future<List<Template>> getAllTemplates();
  Future<List<MapTheme>> getAllThemes();
  Future<GraphSnapshot> getGraphSnapshot();
  Future<Nodes?> getNode({required TypedRecordId id});
  Future<Tag?> getTag({required String key});
  Future<MapTheme?> getTheme({required String key});
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
    required List<(TypedRecordId, double, double, double, double)> positions,
  });
  Future<void> updateRelation({required IRelation input});
  Future<void> updateTag({required Tag tag});
  Future<void> updateTheme({required MapTheme theme});
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

  void dispose() => _api.dispose();

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<TypedRecordId>? relationIds,
  }) => _api.computeRelations(config: config, relationIds: relationIds);

  @override
  Future<ComputedRelation> computeSingleRelation({
    required RelationEngineConfig config,
    required TypedRecordId edgeId,
    required TypedRecordId fromNodeId,
    required TypedRecordId toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    RoutingMode? routingMode,
    double? overrideStartX,
    double? overrideStartY,
    double? overrideEndX,
    double? overrideEndY,
  }) => _api.computeSingleRelation(
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
  Future<void> createTheme({
    required String key,
    required ThemeFields fields,
  }) => _api.createTheme(key: key, fields: fields);

  @override
  Future<void> deleteNodeEntry({required TypedRecordId id}) =>
      _api.deleteNodeEntry(id: id);

  @override
  Future<void> deleteRelation({required TypedRecordId id}) =>
      _api.deleteRelation(id: id);

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
  Future<List<MapTheme>> getAllThemes() => _api.getAllThemes();

  @override
  Future<GraphSnapshot> getGraphSnapshot() => _api.getGraphSnapshot();

  @override
  Future<Nodes?> getNode({required TypedRecordId id}) => _api.getNode(id: id);

  @override
  Future<Tag?> getTag({required String key}) => _api.getTag(key: key);

  @override
  Future<MapTheme?> getTheme({required String key}) => _api.getTheme(key: key);

  @override
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  }) => _api.instantiateTemplate(key: key, targetX: targetX, targetY: targetY);

  @override
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  }) => _api.loadMapFromFile(filePath: filePath, attachmentDir: attachmentDir);

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
  }) => _api.rerouteRelation(record: record, from: from, to: to);

  @override
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  }) => _api.saveMapToFile(filePath: filePath, attachmentDir: attachmentDir);

  @override
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  }) => _api.saveTemplateFromSelection(
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
  }) => _api.updateNodeCachePositions(positions: positions);

  @override
  Future<void> updateRelation({required IRelation input}) =>
      _api.updateRelation(input: input);

  @override
  Future<void> updateTag({required Tag tag}) => _api.updateTag(tag: tag);

  @override
  Future<void> updateTheme({required MapTheme theme}) =>
      _api.updateTheme(theme: theme);

  @override
  Future<void> updateViewportState({required ViewportState state}) =>
      _api.updateViewportState(state: state);
}

/// A proxy [GraphApi] that buffers or returns safe defaults before the underlying FFI handle finishes loading.
class DeferredGraphApi implements GraphApi {
  GraphApi? _handle;

  void attach(GraphApi handle) {
    _handle = handle;
  }

  bool get isAttached => _handle != null;

  void dispose() {
    final h = _handle;
    if (h is RustAppHandleWrapper) {
      h.dispose();
    } else {
      _handle?.close();
    }
  }

  @override
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation}) async {
    await _handle?.applyEntityMutation(mutation: mutation);
  }

  @override
  Future<void> close() async {
    await _handle?.close();
  }

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<TypedRecordId>? relationIds,
  }) async {
    if (_handle == null) return [];
    return await _handle!.computeRelations(config: config, relationIds: relationIds);
  }

  @override
  Future<ComputedRelation> computeSingleRelation({
    required RelationEngineConfig config,
    required TypedRecordId edgeId,
    required TypedRecordId fromNodeId,
    required TypedRecordId toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    RoutingMode? routingMode,
    double? overrideStartX,
    double? overrideStartY,
    double? overrideEndX,
    double? overrideEndY,
  }) async {
    if (_handle != null) {
      return await _handle!.computeSingleRelation(
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
    }
    throw UnimplementedError('GraphApi not yet attached');
  }

  @override
  Stream<GraphEvent> createGraphStream() {
    return _handle?.createGraphStream() ?? const Stream.empty();
  }

  @override
  Future<void> createNode({required Nodes input}) async {
    await _handle?.createNode(input: input);
  }

  @override
  Future<void> createRelation({required IRelation input}) async {
    await _handle?.createRelation(input: input);
  }

  @override
  Future<void> createTag({required Tag tag}) async {
    await _handle?.createTag(tag: tag);
  }

  @override
  Future<void> createTheme({required String key, required ThemeFields fields}) async {
    await _handle?.createTheme(key: key, fields: fields);
  }

  @override
  Future<void> deleteNodeEntry({required TypedRecordId id}) async {
    await _handle?.deleteNodeEntry(id: id);
  }

  @override
  Future<void> deleteRelation({required TypedRecordId id}) async {
    await _handle?.deleteRelation(id: id);
  }

  @override
  Future<void> deleteTag({required String key}) async {
    await _handle?.deleteTag(key: key);
  }

  @override
  Future<void> deleteTemplate({required String key}) async {
    await _handle?.deleteTemplate(key: key);
  }

  @override
  Future<String?> getActiveThemeId() async {
    return await _handle?.getActiveThemeId();
  }

  @override
  Future<List<Tag>> getAllTags() async {
    if (_handle == null) return [];
    return await _handle!.getAllTags();
  }

  @override
  Future<List<Template>> getAllTemplates() async {
    if (_handle == null) return [];
    return await _handle!.getAllTemplates();
  }

  @override
  Future<List<MapTheme>> getAllThemes() async {
    if (_handle == null) return [];
    return await _handle!.getAllThemes();
  }

  @override
  Future<GraphSnapshot> getGraphSnapshot() async {
    if (_handle == null) {
      return const GraphSnapshot(
        nodes: [],
        relations: [],
        metadata: MapData(
          mapName: '',
          viewportState: ViewportState(
            xOffset: 0,
            yOffset: 0,
            zoomLevel: 1.0,
            activeView: 'canvas',
          ),
          displayMode: DisplayMode.importance,
        ),
      );
    }
    return await _handle!.getGraphSnapshot();
  }

  @override
  Future<Nodes?> getNode({required TypedRecordId id}) async {
    return await _handle?.getNode(id: id);
  }

  @override
  Future<Tag?> getTag({required String key}) async {
    return await _handle?.getTag(key: key);
  }

  @override
  Future<MapTheme?> getTheme({required String key}) async {
    return await _handle?.getTheme(key: key);
  }

  @override
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  }) async {
    await _handle?.instantiateTemplate(key: key, targetX: targetX, targetY: targetY);
  }

  @override
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  }) async {
    await _handle?.loadMapFromFile(filePath: filePath, attachmentDir: attachmentDir);
  }

  @override
  Future<List<Nodes>> querySearch({required String query}) async {
    if (_handle == null) return [];
    return await _handle!.querySearch(query: query);
  }

  @override
  Future<HistoryRecord?> redo() async {
    return await _handle?.redo();
  }

  @override
  Future<int> redoCount() async {
    return await _handle?.redoCount() ?? 0;
  }

  @override
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  }) async {
    await _handle?.rerouteRelation(record: record, from: from, to: to);
  }

  @override
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  }) async {
    await _handle?.saveMapToFile(filePath: filePath, attachmentDir: attachmentDir);
  }

  @override
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  }) async {
    await _handle?.saveTemplateFromSelection(
      name: name,
      nodeKeys: nodeKeys,
      relationKeys: relationKeys,
    );
  }

  @override
  Future<void> setActiveTheme({required String themeKey}) async {
    await _handle?.setActiveTheme(themeKey: themeKey);
  }

  @override
  Future<void> setActiveThemeId({required String themeId}) async {
    await _handle?.setActiveThemeId(themeId: themeId);
  }

  @override
  Future<HistoryRecord?> undo() async {
    return await _handle?.undo();
  }

  @override
  Future<int> undoCount() async {
    return await _handle?.undoCount() ?? 0;
  }

  @override
  Future<void> updateNode({required Nodes input}) async {
    await _handle?.updateNode(input: input);
  }

  @override
  Future<void> updateNodeCachePositions({
    required List<(TypedRecordId, double, double, double, double)> positions,
  }) async {
    await _handle?.updateNodeCachePositions(positions: positions);
  }

  @override
  Future<void> updateRelation({required IRelation input}) async {
    await _handle?.updateRelation(input: input);
  }

  @override
  Future<void> updateTag({required Tag tag}) async {
    await _handle?.updateTag(tag: tag);
  }

  @override
  Future<void> updateTheme({required MapTheme theme}) async {
    await _handle?.updateTheme(theme: theme);
  }

  @override
  Future<void> updateViewportState({required ViewportState state}) async {
    await _handle?.updateViewportState(state: state);
  }
}
