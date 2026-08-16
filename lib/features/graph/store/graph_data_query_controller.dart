import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'spatial_index.dart';
import 'relation_engine_state.dart';
import 'graph_data_query.dart';
import 'modules/graph_store.dart';
import 'modules/graph_spatial.dart';
import 'graph_api.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class GraphDataQueryController implements GraphDataQuery {
  final GraphStore store = GraphStore();
  final GraphSpatial spatial = GraphSpatial();
  @override
  late final RelationEngineState relationEngine;

  @override
  final ValueNotifier<Rect?> optAreaNotifier = ValueNotifier<Rect?>(null);

  bool _isLoading = false;
  String? _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  void setLoading(bool val) => _isLoading = val;
  void setError(String? val) => _errorMessage = val;

  final StreamController<GraphEntityUpdate> _entityUpdateController =
      StreamController<GraphEntityUpdate>.broadcast();

  @override
  Stream<GraphEntityUpdate> get onEntityUpdate =>
      _entityUpdateController.stream;

  void publishUpdate(GraphEntityUpdate update) {
    if (update.id != null) {
      final node = store.nodeLookup[update.id!];
      if (node != null) {
        if (update.type == GraphUpdateType.size && update.payload is Size) {
          node.size = update.payload as Size;
          spatial.spatialIndex.updateNode(
            node.id,
            node.parentContainerId,
            node.position,
            node.position,
            node.size,
          );
        } else if (update.type == GraphUpdateType.position && update.payload is Offset) {
          final newPos = update.payload as Offset;
          spatial.spatialIndex.updateNode(
            node.id,
            node.parentContainerId,
            node.position,
            newPos,
            node.size,
          );
          node.position = newPos;
        }
      }
    }
    _entityUpdateController.add(update);
  }

  void triggerUpdate() {
    publishUpdate(
      GraphEntityUpdate(tableName: '', type: GraphUpdateType.reset),
    );
  }

  @override
  SpatialHashGrid get spatialGrid => spatial.spatialGrid;

  @override
  HierarchicalSpatialIndex get spatialIndex => spatial.spatialIndex;

  @override
  Map<RawUuid, UiNode> get nodeLookup => store.nodeLookup;

  @override
  Map<RawUuid, UiRelation> get relationLookup => store.relationLookup;

  @override
  Iterable<UiRelation> get relations => store.relations;

  BoundingBox _canvasBounds = const BoundingBox(
    minX: 0,
    minY: 0,
    maxX: 1000,
    maxY: 1000,
  );

  @override
  BoundingBox get canvasBounds => _canvasBounds;

  set canvasBounds(BoundingBox bounds) {
    _canvasBounds = bounds;
  }

  final GraphApi api;

  GraphDataQueryController(this.api) {
    relationEngine = RelationEngineState(
      api: api,
      nodeLookupGetter: () => nodeLookup,
      relationLookupGetter: () => relationLookup,
    );
  }

  Future<List<DatabaseSearchResult>> searchDatabase(String term) async {
    final rustNodes = await api.querySearch(query: term);
    final results = <DatabaseSearchResult>[];
    for (final rustNode in rustNodes) {
      if (rustNode is Nodes_INode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key.uuid,
            type: DatabaseSearchResultType.infoNode,
            text: node.content.text,
          ),
        );
      } else if (rustNode is Nodes_TaskNode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key.uuid,
            type: DatabaseSearchResultType.taskNode,
            text: node.content.text,
            state: node.state.name,
          ),
        );
      } else if (rustNode is Nodes_InterNode) {
        final node = rustNode.field0;
        results.add(
          DatabaseSearchResult(
            key: node.id.key.uuid,
            type: DatabaseSearchResultType.relation,
            text: node.verb,
          ),
        );
      }
    }
    return results;
  }

  void dispose() {
    _entityUpdateController.close();
    relationEngine.dispose();
    optAreaNotifier.dispose();
  }

  @override
  List<UiNode> nodesInScope(ViewportScope scope) {
    if (scope is RootViewportScope) {
      return store.nodeLookup.values.where((n) => n.parentContainerId == null).toList();
    }
    final containerId = (scope as ContainerViewportScope).containerId;
    return store.nodeLookup.values.where((n) => n.parentContainerId == containerId).toList();
  }

  @override
  List<UiRelation> relationsInScope(ViewportScope scope) {
    if (scope is RootViewportScope) {
      return store.relations.where((r) {
        final fromNode = store.nodeLookup[r.fromNodeId];
        final toNode = store.nodeLookup[r.toNodeId];
        if (fromNode == null || toNode == null) return false;
        return fromNode.parentContainerId == null && toNode.parentContainerId == null;
      }).toList();
    }
    final containerId = (scope as ContainerViewportScope).containerId;
    return store.relations.where((r) {
      final fromNode = store.nodeLookup[r.fromNodeId];
      final toNode = store.nodeLookup[r.toNodeId];
      if (fromNode == null || toNode == null) return false;
      return fromNode.parentContainerId == containerId &&
             toNode.parentContainerId == containerId;
    }).toList();
  }

  @override
  bool isNodeInScope(RawUuid nodeId, ViewportScope scope) {
    final node = store.nodeLookup[nodeId];
    if (node == null) return false;
    if (scope is RootViewportScope) return node.parentContainerId == null;
    return node.parentContainerId == (scope as ContainerViewportScope).containerId;
  }
}

