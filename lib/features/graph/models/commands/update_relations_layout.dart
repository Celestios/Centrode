import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';

final Logger _log = Logger('UpdateRelationsLayoutCommand');

class UpdateRelationsLayoutCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final Map<String, RelationLayout?> oldLayouts;
  final Map<String, RelationLayout?> newLayouts;
  final Map<String, RelationStyle?> oldStyles;
  final Map<String, RelationStyle?> newStyles;
  final Map<String, UiRelation> oldRelations;
  final GraphCommandContext controller;

  UpdateRelationsLayoutCommand({
    required this.targetId,
    required this.api,
    required this.oldLayouts,
    required this.newLayouts,
    required this.oldStyles,
    required this.newStyles,
    required this.oldRelations,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    _log.info('execute UpdateRelationsLayout count=${newLayouts.length}');
    for (final id in newLayouts.keys) {
      final (forwardPatches, reversePatches) = buildRelationLayoutPatches(
        oldLayouts[id], newLayouts[id], oldStyles[id], newStyles[id],
      );

      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: frb.RecordStrings(table: 'IRelation', key: id),
          forward: EntityPatch.relation(forwardPatches),
          reverse: EntityPatch.relation(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateRelationsLayout count=${oldRelations.length}');
    for (final id in oldRelations.keys) {
      final oldRelation = oldRelations[id]!;
      controller.store.relationLookup[id] = oldRelation;
      controller.styleUpdater?.updateStyleForRelation(id);
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.relationLayout,
          payload: oldRelation.layout,
        ),
      );
    }
    controller.triggerUpdate();
  }
}
