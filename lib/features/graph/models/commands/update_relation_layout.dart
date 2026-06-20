import 'package:mycelium/infrastructure/telemetry/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_data_query.dart';
import '../graph_relation.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';

final Logger _log = Logger('UpdateRelationLayoutCommand');

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
  final GraphCommandContext controller;

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
    _log.info('execute UpdateRelationLayout key=$targetId table=$tableName');
    final (forwardPatches, reversePatches) = buildRelationLayoutPatches(
      oldLayout, newLayout, oldStyle, newStyle,
    );

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
    _log.info('undo UpdateRelationLayout key=$targetId');
    controller.store.relationLookup[targetId] = oldRelation;
    controller.styleUpdater?.updateStyleForRelation(targetId);
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
