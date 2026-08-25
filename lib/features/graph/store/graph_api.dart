import 'dart:async';
import 'dart:typed_data';
import 'package:centrode/features/graph/store/api/api.dart';
import 'package:centrode/src/rust/bridge/api.dart';
import 'package:centrode/src/rust/bridge/stream.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/nodes.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/domain/relations.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/tags.dart';
import 'package:centrode/src/rust/domain/theme.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:centrode/src/rust/repo/history.dart';

export 'package:centrode/features/graph/store/api/api.dart';

/// Unified composite interface for the graph engine store and FFI surface.
abstract interface class GraphApi
    implements
        NodeApi,
        RelationApi,
        LayoutApi,
        HistoryApi,
        ThemeApi,
        TemplateApi,
        TagApi,
        AssetApi,
        MlApi,
        ViewportApi {}

/// Direct FFI-backed implementation of [GraphApi] wrapping [AppHandle].
class RustGraphApi implements GraphApi {
  final AppHandle _api;

  RustGraphApi(this._api);

  AppHandle get handle => _api;

  // NodeApi
  @override
  Future<void> createNode({required Nodes input}) => _api.createNode(input: input);

  @override
  Future<Nodes?> getNode({required TypedRecordId id}) => _api.getNode(id: id);

  @override
  Future<void> updateNode({required Nodes input}) => _api.updateNode(input: input);

  @override
  Future<void> deleteNodeEntry({required TypedRecordId id}) => _api.deleteNodeEntry(id: id);

  @override
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation}) =>
      _api.applyEntityMutation(mutation: mutation);

  @override
  Future<void> updateNodeCachePositions({
    required List<(TypedRecordId, double, double, double, double)> positions,
  }) =>
      _api.updateNodeCachePositions(positions: positions);

  // RelationApi
  @override
  Future<void> createRelation({required IRelation input}) =>
      _api.createRelation(input: input);

  @override
  Future<void> updateRelation({required IRelation input}) =>
      _api.updateRelation(input: input);

  @override
  Future<void> deleteRelation({required TypedRecordId id}) =>
      _api.deleteRelation(id: id);

  @override
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  }) =>
      _api.rerouteRelation(record: record, from: from, to: to);

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<TypedRecordId>? relationIds,
  }) =>
      _api.computeRelations(config: config, relationIds: relationIds);

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

  // LayoutApi
  @override
  Future<void> triggerLayoutOptimization({
    required LayoutConfig config,
    List<LayoutPatch> livePositions = const [],
  }) =>
      _api.triggerLayoutOptimization(config: config, livePositions: livePositions);

  @override
  Future<(double, double)> computeAutoPlacement({
    required TypedRecordId sourceId,
    required PortSide portSide,
  }) =>
      _api.computeAutoPlacement(sourceId: sourceId, portSide: portSide);

  @override
  Future<void> setAlignmentConstraint({
    required List<TypedRecordId> nodeIds,
    required Axis axis,
  }) =>
      _api.setAlignmentConstraint(nodeIds: nodeIds, axis: axis);

  @override
  Future<void> addAnchorSpring({
    required TypedRecordId nodeId,
    required double x,
    required double y,
    required double strength,
  }) =>
      _api.addAnchorSpring(nodeId: nodeId, x: x, y: y, strength: strength);

  // HistoryApi
  @override
  Future<HistoryRecord?> undo() => _api.undo();

  @override
  Future<int> undoCount() => _api.undoCount();

  @override
  Future<HistoryRecord?> redo() => _api.redo();

  @override
  Future<int> redoCount() => _api.redoCount();

  // ThemeApi
  @override
  Future<void> createTheme({required String key, required ThemeFields fields}) =>
      _api.createTheme(key: key, fields: fields);

  @override
  Future<MapTheme?> getTheme({required String key}) => _api.getTheme(key: key);

  @override
  Future<List<MapTheme>> getAllThemes() => _api.getAllThemes();

  @override
  Future<void> updateTheme({required MapTheme theme}) => _api.updateTheme(theme: theme);

  @override
  Future<void> setActiveTheme({required String themeKey}) =>
      _api.setActiveTheme(themeKey: themeKey);

  @override
  Future<void> setActiveThemeId({required String themeId}) =>
      _api.setActiveThemeId(themeId: themeId);

  @override
  Future<String?> getActiveThemeId() => _api.getActiveThemeId();

  // TemplateApi
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
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  }) =>
      _api.instantiateTemplate(key: key, targetX: targetX, targetY: targetY);

  @override
  Future<List<Template>> getAllTemplates() => _api.getAllTemplates();

  @override
  Future<void> deleteTemplate({required String key}) =>
      _api.deleteTemplate(key: key);

  // TagApi
  @override
  Future<void> createTag({required Tag tag}) => _api.createTag(tag: tag);

  @override
  Future<Tag?> getTag({required String key}) => _api.getTag(key: key);

  @override
  Future<List<Tag>> getAllTags() => _api.getAllTags();

  @override
  Future<void> updateTag({required Tag tag}) => _api.updateTag(tag: tag);

  @override
  Future<void> deleteTag({required String key}) => _api.deleteTag(key: key);

  // AssetApi
  @override
  Future<Attachment> ingestAsset({
    required String assetDir,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  }) =>
      _api.ingestAsset(
        assetDir: assetDir,
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

  @override
  Future<String> getAssetAbsolutePath({
    required String assetDir,
    required String hash,
    required String extension,
  }) =>
      _api.getAssetAbsolutePath(
        assetDir: assetDir,
        hash: hash,
        extension: extension,
      );

  @override
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  }) =>
      _api.loadMapFromFile(
        filePath: filePath,
        attachmentDir: attachmentDir,
      );

  @override
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  }) =>
      _api.saveMapToFile(
        filePath: filePath,
        attachmentDir: attachmentDir,
      );

  // MlApi
  @override
  Future<String> detectMapLanguage({required List<String> nodeTexts}) =>
      _api.detectMapLanguage(nodeTexts: nodeTexts);

  @override
  Future<List<String>> predictRelationLabels({
    required String sourceText,
    required String targetText,
    String? language,
    required BigInt limit,
  }) =>
      _api.predictRelationLabels(
        sourceText: sourceText,
        targetText: targetText,
        language: language,
        limit: limit,
      );

  @override
  Future<List<String>> searchSimilarLabels({
    required String query,
    required BigInt limit,
  }) =>
      _api.searchSimilarLabels(query: query, limit: limit);

  @override
  Future<Float32List> embedText({required String text}) =>
      _api.embedText(text: text);

  @override
  Future<void> initEmbedderModel({
    required Uint8List weightsBytes,
    required Uint8List tokenizerBytes,
    Uint8List? configBytes,
  }) =>
      _api.initEmbedderModel(
        weightsBytes: weightsBytes,
        tokenizerBytes: tokenizerBytes,
        configBytes: configBytes,
      );

  @override
  Future<RelationStyle?> getRelationSpec({required String verb}) =>
      _api.getRelationSpec(verb: verb);

  @override
  Future<List<(String, RelationStyle)>> listRelationSpecs() =>
      _api.listRelationSpecs();

  // ViewportApi
  @override
  Future<void> updateViewportState({required ViewportState state}) =>
      _api.updateViewportState(state: state);

  @override
  Future<BoundingBox?> getOptArea() => _api.getOptArea();

  @override
  Future<void> setOptArea({BoundingBox? bounds}) =>
      _api.setOptArea(bounds: bounds);

  @override
  Future<GraphSnapshot> getGraphSnapshot() => _api.getGraphSnapshot();

  @override
  Future<List<Nodes>> querySearch({required String query}) =>
      _api.querySearch(query: query);

  @override
  Stream<GraphEvent> createGraphStream() => _api.createGraphStream();

  @override
  Future<void> close() => _api.close();
}
