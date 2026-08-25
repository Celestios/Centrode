import 'dart:async';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/relations.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/relation_engine/computed.dart';
import 'package:centrode/src/rust/relation_engine/config.dart';

abstract interface class RelationApi {
  Future<void> createRelation({required IRelation input});
  Future<void> updateRelation({required IRelation input});
  Future<void> deleteRelation({required TypedRecordId id});
  Future<void> rerouteRelation({
    required TypedRecordId record,
    required TypedRecordId from,
    required TypedRecordId to,
  });
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
}
