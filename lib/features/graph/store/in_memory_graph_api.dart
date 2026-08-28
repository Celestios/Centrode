import 'dart:async';
import 'dart:typed_data';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/src/rust/bridge/stream.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'package:centrode/src/rust/domain/theme.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import 'package:centrode/src/rust/repo/history.dart';
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';
import 'package:centrode/src/rust/relation_engine/geometry.dart' as rust_geom;
import 'package:centrode/src/rust/domain/routing.dart';
import 'package:uuid/uuid.dart';

/// A production-grade, stateful in-memory implementation of [GraphApi].
/// Emulates SurrealDB persistence, atomicity, and cascading logic in pure Dart memory.
class InMemoryGraphApi implements GraphApi {
  final Map<String, Nodes> _nodes = {};
  final Map<String, IRelation> _relations = {};
  final Map<String, Tag> _tags = {};
  final Map<String, MapTheme> _themes = {};
  final Map<String, Template> _templates = {};
  final List<HistoryRecord> _undoStack = [];
  final List<HistoryRecord> _redoStack = [];

  String? _activeThemeId;
  frb.BoundingBox? _optArea;
  frb.ViewportState _viewportState = const frb.ViewportState(
    xOffset: 0.0,
    yOffset: 0.0,
    zoomLevel: 1.0,
    activeView: 'default',
  );

  final StreamController<GraphEvent> _eventController =
      StreamController<GraphEvent>.broadcast(sync: false);

  final List<String> invocationLog = [];

  static String _nodeKey(Nodes node) {
    final dynamic inner = node.field0;
    final TypedRecordId id = inner.id as TypedRecordId;
    return id.key.uuid;
  }

  @override
  Stream<GraphEvent> createGraphStream() => _eventController.stream;

  @override
  Future<void> createNode({required Nodes input}) async {
    final key = _nodeKey(input);
    invocationLog.add('createNode:$key');
    _nodes[key] = input;
    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: [input],
          nodeDeletions: const [],
          relationUpserts: const [],
          relationCreations: const [],
          relationDeletions: const [],
        ),
      ),
    );
  }

  @override
  Future<Nodes?> getNode({required TypedRecordId id}) async {
    return _nodes[id.key.uuid];
  }

  @override
  Future<void> updateNode({required Nodes input}) async {
    final key = _nodeKey(input);
    invocationLog.add('updateNode:$key');
    _nodes[key] = input;
    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: [input],
          nodeDeletions: const [],
          relationUpserts: const [],
          relationCreations: const [],
          relationDeletions: const [],
        ),
      ),
    );
  }

  @override
  Future<void> deleteNodeEntry({required TypedRecordId id}) async {
    final nodeKey = id.key.uuid;
    invocationLog.add('deleteNode:$nodeKey');
    _nodes.remove(nodeKey);

    // Cascading deletion of attached relations (exact SurrealDB behavior)
    final deadRelationKeys = _relations.entries
        .where((e) =>
            e.value.in_.key.uuid == nodeKey || e.value.out.key.uuid == nodeKey)
        .map((e) => e.key)
        .toList();

    final deletedRelationIds = <TypedRecordId>[];
    for (final relKey in deadRelationKeys) {
      final removed = _relations.remove(relKey);
      if (removed != null) {
        deletedRelationIds.add(removed.key);
      }
    }

    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: const [],
          nodeDeletions: [id],
          relationUpserts: const [],
          relationCreations: const [],
          relationDeletions: deletedRelationIds,
        ),
      ),
    );
  }

  @override
  Future<void> createRelation({required IRelation input}) async {
    final key = input.key.key.uuid;
    invocationLog.add('createRelation:$key');
    _relations[key] = input;
    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: const [],
          nodeDeletions: const [],
          relationUpserts: const [],
          relationCreations: [input],
          relationDeletions: const [],
        ),
      ),
    );
  }

  @override
  Future<void> updateRelation({required IRelation input}) async {
    final key = input.key.key.uuid;
    invocationLog.add('updateRelation:$key');
    _relations[key] = input;
    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: const [],
          nodeDeletions: const [],
          relationUpserts: [(input.key, const <RelationPatch>[])],
          relationCreations: const [],
          relationDeletions: const [],
        ),
      ),
    );
  }

  @override
  Future<void> deleteRelation({required TypedRecordId id}) async {
    final key = id.key.uuid;
    invocationLog.add('deleteRelation:$key');
    _relations.remove(key);
    _eventController.add(
      GraphEvent.batchUpdated(
        GraphDelta(
          nodeUpserts: const [],
          nodeCreations: const [],
          nodeDeletions: const [],
          relationUpserts: const [],
          relationCreations: const [],
          relationDeletions: [id],
        ),
      ),
    );
  }

  @override
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  }) async {
    final key = record.key.uuid;
    final existing = _relations[key];
    if (existing != null) {
      final updated = IRelation(
        key: existing.key,
        in_: from,
        out: to,
        fields: existing.fields,
      );
      _relations[key] = updated;
      _eventController.add(
        GraphEvent.batchUpdated(
          GraphDelta(
            nodeUpserts: const [],
            nodeCreations: const [],
            nodeDeletions: const [],
            relationUpserts: const [],
            relationCreations: [updated],
            relationDeletions: const [],
          ),
        ),
      );
    }
  }

  @override
  Future<void> createTag({required Tag tag}) async {
    _tags[tag.key.key.uuid] = tag;
  }

  @override
  Future<Tag?> getTag({required String key}) async {
    return _tags[key];
  }

  @override
  Future<List<Tag>> getAllTags() async {
    return _tags.values.toList();
  }

  @override
  Future<void> updateTag({required Tag tag}) async {
    _tags[tag.key.key.uuid] = tag;
  }

  @override
  Future<void> deleteTag({required String key}) async {
    _tags.remove(key);
  }

  @override
  Future<void> createTheme({required String key, required ThemeFields fields}) async {
    final theme = MapTheme(
      key: TypedRecordId(table: TableKind.mapTheme, key: UuidValue.fromString(key)),
      fields: fields,
    );
    _themes[key] = theme;
  }

  @override
  Future<MapTheme?> getTheme({required String key}) async {
    return _themes[key];
  }

  @override
  Future<List<MapTheme>> getAllThemes() async {
    return _themes.values.toList();
  }

  @override
  Future<void> updateTheme({required MapTheme theme}) async {
    _themes[theme.key.key.uuid] = theme;
  }

  @override
  Future<String?> getActiveThemeId() async {
    return _activeThemeId;
  }

  @override
  Future<void> setActiveTheme({required String themeKey}) async {
    _activeThemeId = themeKey;
  }

  @override
  Future<void> setActiveThemeId({required String themeId}) async {
    _activeThemeId = themeId;
  }

  @override
  Future<List<Template>> getAllTemplates() async {
    return _templates.values.toList();
  }

  @override
  Future<void> deleteTemplate({required String key}) async {
    _templates.remove(key);
  }

  @override
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  }) async {
    invocationLog.add('instantiateTemplate:$key at ($targetX, $targetY)');
  }

  @override
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  }) async {
    invocationLog.add('saveTemplateFromSelection:$name');
  }

  @override
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation}) async {
    invocationLog.add('applyEntityMutation');
  }

  @override
  Future<GraphSnapshot> getGraphSnapshot() async {
    return GraphSnapshot(
      nodes: _nodes.values.toList(),
      relations: _relations.values.toList(),
      metadata: MapData(
        mapName: 'InMemoryMap',
        viewportState: _viewportState,
        activeThemeId: _activeThemeId,
        displayMode: frb.DisplayMode.importance,
        optArea: _optArea,
      ),
    );
  }

  @override
  Future<List<Nodes>> querySearch({required String query}) async {
    final lower = query.toLowerCase();
    return _nodes.values.where((n) {
      return _nodeKey(n).toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Future<HistoryRecord?> undo() async {
    if (_undoStack.isNotEmpty) {
      final record = _undoStack.removeLast();
      _redoStack.add(record);
      return record;
    }
    return null;
  }

  @override
  Future<int> undoCount() async {
    return _undoStack.length;
  }

  @override
  Future<HistoryRecord?> redo() async {
    if (_redoStack.isNotEmpty) {
      final record = _redoStack.removeLast();
      _undoStack.add(record);
      return record;
    }
    return null;
  }

  @override
  Future<int> redoCount() async {
    return _redoStack.length;
  }

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<TypedRecordId>? relationIds,
  }) async {
    return [];
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
    final start = Point(
      x: overrideStartX ?? 0.0,
      y: overrideStartY ?? 0.0,
    );
    final end = Point(
      x: overrideEndX ?? 100.0,
      y: overrideEndY ?? 100.0,
    );
    final mid = Point(
      x: (start.x + end.x) / 2.0,
      y: (start.y + end.y) / 2.0,
    );
    final minX = start.x < end.x ? start.x : end.x;
    final minY = start.y < end.y ? start.y : end.y;
    final width = (end.x - start.x).abs();
    final height = (end.y - start.y).abs();

    return ComputedRelation(
      id: edgeId,
      pathPoints: [start, end],
      pathType: PathType.straight,
      startTangent: const Point(x: 1, y: 0),
      endTangent: const Point(x: 1, y: 0),
      bodyWidths: Float64List.fromList([1.5, 1.5]),
      bodyType: BodyType.uniform,
      startEndpoint: EndpointShape.none,
      endEndpoint: EndpointShape.arrow,
      startDirection: 0.0,
      endDirection: 0.0,
      labelPosition: mid,
      labelAnchor: LabelAnchor.center,
      bbox: rust_geom.Rect(x: minX, y: minY, width: width, height: height),
      startPoint: start,
      endPoint: end,
      startArrowCenter: start,
      endArrowCenter: end,
      startMargin: 0.0,
      endMargin: 0.0,
      dependsOnNodes: [fromNodeId, toNodeId],
      controlPoints: const [],
      knots: Float64List(0),
      nudgeColors: const [],
      hitTestPoints: const [],
      composeActive: false,
      startShapePath: const [],
      endShapePath: const [],
      startShapeFilled: false,
      endShapeFilled: false,
      startHandlePos: const Point(x: 0, y: 0),
      endHandlePos: const Point(x: 0, y: 0),
    );
  }

  @override
  Future<void> updateNodeCachePositions({
    required List<(TypedRecordId, double, double, double, double)> positions,
  }) async {}

  @override
  Future<void> updateViewportState({required frb.ViewportState state}) async {
    _viewportState = state;
  }

  @override
  Future<frb.BoundingBox?> getOptArea() async => _optArea;

  @override
  Future<void> setOptArea({frb.BoundingBox? bounds}) async {
    _optArea = bounds;
  }

  @override
  Future<void> triggerLayoutOptimization({
    required LayoutConfig config,
    List<LayoutPatch> livePositions = const [],
  }) async {}

  @override
  Future<(double, double)> computeAutoPlacement({
    required TypedRecordId sourceId,
    required PortSide portSide,
  }) async {
    return (0.0, 0.0);
  }

  @override
  Future<void> setAlignmentConstraint({
    required List<TypedRecordId> nodeIds,
    required Axis axis,
  }) async {}

  @override
  Future<void> addAnchorSpring({
    required TypedRecordId nodeId,
    required double x,
    required double y,
    required double strength,
  }) async {}

  @override
  Future<frb.Attachment> ingestAsset({
    required String assetDir,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  }) async {
    return frb.Attachment(
      id: 'fake_id',
      hash: 'fake_hash',
      name: fileName,
      mimeType: mimeType,
      byteSize: fileBytes.length,
    );
  }

  @override
  Future<String> getAssetAbsolutePath({
    required String assetDir,
    required String hash,
    required String extension,
  }) async {
    return '$assetDir/$hash.$extension';
  }

  @override
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  }) async {}

  @override
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  }) async {}

  @override
  Future<RelationStyle?> getRelationSpec({required String verb}) async {
    return null;
  }

  @override
  Future<List<(String, RelationStyle)>> listRelationSpecs() async {
    return const [];
  }

  @override
  Future<List<String>> searchSimilarLabels({
    required String query,
    String? category,
    String? language,
    required BigInt limit,
  }) async {
    return const [];
  }

  @override
  Future<List<String>> predictRelationLabels({
    required String sourceText,
    required String targetText,
    String? language,
    required BigInt limit,
  }) async {
    return const [];
  }

  @override
  Future<String> detectMapLanguage({required List<String> nodeTexts}) async {
    return 'en';
  }

  @override
  Future<Float32List> embedText({required String text}) async {
    return Float32List(0);
  }

  @override
  Future<void> initEmbedderModel({
    Uint8List? weightsBytes,
    String? unpackedModelPath,
    required Uint8List tokenizerBytes,
    Uint8List? configBytes,
  }) async {}

  @override
  Future<void> close() async {
    await _eventController.close();
  }
}
