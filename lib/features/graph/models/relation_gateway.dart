import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/relations.dart';
import 'package:mycelium/src/rust/domain/relation_engine/config.dart';
import 'package:mycelium/src/rust/domain/relation_engine/computed.dart';

abstract class RelationGateway {
  Future<void> createRelation({required IRelation input});
  Future<void> deleteRelation({required String table, required String key});
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation});
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<String>? relationIds,
  });
}

class AppRelationGateway implements RelationGateway {
  final AppHandle _api;
  AppRelationGateway(this._api);

  @override
  Future<void> createRelation({required IRelation input}) =>
      _api.createRelation(input: input);

  @override
  Future<void> deleteRelation({required String table, required String key}) =>
      _api.deleteRelation(table: table, key: key);

  @override
  Future<void> applyEntityMutation({required SymmetricEntityPatch mutation}) =>
      _api.applyEntityMutation(mutation: mutation);

  @override
  Future<List<ComputedRelation>> computeRelations({
    required RelationEngineConfig config,
    List<String>? relationIds,
  }) =>
      _api.computeRelations(config: config, relationIds: relationIds);
}
