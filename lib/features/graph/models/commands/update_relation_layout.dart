import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_controller.dart';
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';

class UpdateRelationLayoutCommand extends GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final RelationLayout? oldLayout;
  final RelationLayout? newLayout;
  final RelationStyle? oldStyle;
  final RelationStyle? newStyle;
  final UiRelation oldRelation;
  final GraphDataController controller;

  UpdateRelationLayoutCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldLayout,
    this.newLayout,
    this.oldStyle,
    this.newStyle,
    required this.oldRelation,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
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
        id: frb.RecordStrings(table: tableName, key: targetId),
        forward: EntityPatch.relation(forwardPatches),
        reverse: EntityPatch.relation(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
  }

  @override
  void undo() {
    controller.store.relationLookup[targetId] = oldRelation;
    controller.publishUpdate(
      GraphEntityUpdate(
        id: targetId,
        tableName: tableName,
        type: GraphUpdateType.relationLayout,
        payload: oldRelation.layout,
      ),
    );
    controller.triggerUpdate();
  }
}

