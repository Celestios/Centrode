import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';

class UpdateRelationsLayoutCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final Map<String, RelationLayout?> oldLayouts;
  final Map<String, RelationLayout?> newLayouts;
  final Map<String, RelationStyle?> oldStyles;
  final Map<String, RelationStyle?> newStyles;
  final Map<String, UiRelation> oldRelations;
  final GraphDataController controller;

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
    for (final id in newLayouts.keys) {
      final newLayout = newLayouts[id];
      final oldLayout = oldLayouts[id];
      final newStyle = newStyles[id];
      final oldStyle = oldStyles[id];
      final tableName = 'IRelation';

      final List<RelationPatch> forwardPatches = [];
      final List<RelationPatch> reversePatches = [];

      if (newLayout != null || oldLayout != null) {
        forwardPatches.add(RelationPatch.layout(newLayout));
        reversePatches.add(RelationPatch.layout(oldLayout));
      }
      if (newStyle != null || oldStyle != null) {
        forwardPatches.add(RelationPatch.style(newStyle));
        reversePatches.add(RelationPatch.style(oldStyle));
      }

      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: frb.RecordStrings(table: tableName, key: id),
          forward: EntityPatch.relation(forwardPatches),
          reverse: EntityPatch.relation(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
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
