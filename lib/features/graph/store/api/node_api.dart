import 'dart:async';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/domain/types.dart';

abstract interface class NodeApi {
  Future<void> createNode({required Nodes input});
  Future<Nodes?> getNode({required TypedRecordId id});
  Future<void> updateNode({required Nodes input});
  Future<void> deleteNodeEntry({required TypedRecordId id});
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation});
  Future<void> updateNodeCachePositions({
    required List<(TypedRecordId, double, double, double, double)> positions,
  });
}
