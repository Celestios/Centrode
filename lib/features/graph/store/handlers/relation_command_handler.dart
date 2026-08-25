import 'package:centrode/shared/logging.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import '../../models/graph_relation.dart';
import '../command_queue_processor.dart';
import '../modules/graph_relation_mutations.dart';
import '../api/relation_api.dart';
import '../command_processor.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Command handler managing relation mutations, layouts, and engine cache notification.
class RelationCommandHandler {
  final Logger _log = Logger('RelationCommandHandler');
  final CommandQueueProcessor context;
  final RelationApi api;
  final CommandProcessor processor;
  late final GraphRelationMutations mutations;

  RelationCommandHandler({
    required this.context,
    required this.api,
    required this.processor,
  }) {
    mutations = GraphRelationMutations(context);
  }

  UiRelation? createRelation(
    RawUuid fromId,
    RawUuid toId, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  }) {
    final relation = mutations.createRelation(
      fromId,
      toId,
      fromSide: fromSide,
      toSide: toSide,
      verb: verb,
    );

    final fromNode = context.store.nodeLookup[fromId];
    final toNode = context.store.nodeLookup[toId];
    if (relation != null) {
      context.relationEngine.onRelationAdded(
        relation,
        fromNode: fromNode,
        toNode: toNode,
      );
    }
    return relation;
  }

  Future<void> deleteRelation(RawUuid id) async {
    _log.info('deleteRelation id=$id');
    await mutations.deleteRelation(id);
    context.relationEngine.onRelationDeleted(id);
  }

  void updateRelationLayout(
    RawUuid id, {
    RawUuid? fromNodeId,
    RawUuid? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  }) {
    mutations.updateRelationLayout(
      id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      fromSide: fromSide,
      toSide: toSide,
      strategyType: strategyType,
    );
    context.relationEngine.onRelationLayoutUpdated(id);
  }

  void updateRelationsLayout(List<RawUuid> ids, {String? strategyType}) {
    mutations.updateRelationsLayout(ids, strategyType: strategyType);
    for (final id in ids) {
      context.relationEngine.onRelationLayoutUpdated(id);
    }
  }
}
