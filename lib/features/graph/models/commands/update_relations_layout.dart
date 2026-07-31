import 'package:centrode/shared/logging.dart';
import '../../store/graph_api.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/patches.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('UpdateRelationsLayoutCommand');

class UpdateRelationsLayoutCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final GraphApi api;
  final Map<RawUuid, RelationLayout?> oldLayouts;
  final Map<RawUuid, RelationLayout?> newLayouts;
  final Map<RawUuid, RelationStyle?> oldStyles;
  final Map<RawUuid, RelationStyle?> newStyles;
  final Map<RawUuid, UiRelation> oldRelations;
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
        oldLayouts[id],
        newLayouts[id],
        oldStyles[id],
        newStyles[id],
      );

      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: parseTypedRecordId('IRelation', id),
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
