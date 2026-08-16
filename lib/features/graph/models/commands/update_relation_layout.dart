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

final Logger _log = Logger('UpdateRelationLayoutCommand');

class UpdateRelationLayoutCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final String tableName;
  final GraphApi api;
  final RelationLayout? oldLayout;
  final RelationLayout? newLayout;
  final RelationStyle? oldStyle;
  final RelationStyle? newStyle;
  final RawUuid? newFromId;
  final RawUuid? newToId;
  final String? fromNodeTable;
  final String? toNodeTable;
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
    this.newFromId,
    this.newToId,
    this.fromNodeTable,
    this.toNodeTable,
    required this.oldRelation,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    _log.info('execute UpdateRelationLayout key=$targetId table=$tableName');
    final (forwardPatches, reversePatches) = buildRelationLayoutPatches(
      oldLayout,
      newLayout,
      oldStyle,
      newStyle,
      oldFromId: oldRelation.fromNodeId,
      newFromId: newFromId ?? oldRelation.fromNodeId,
      oldToId: oldRelation.toNodeId,
      newToId: newToId ?? oldRelation.toNodeId,
      fromNodeTable: fromNodeTable ?? oldRelation.fromNodeTable,
      toNodeTable: toNodeTable ?? oldRelation.toNodeTable,
    );

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: parseTypedRecordId(tableName, targetId),
        forward: EntityPatch.relation(forwardPatches),
        reverse: EntityPatch.relation(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
      controller.relationEngine.onRelationLayoutUpdated(targetId);
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateRelationLayout key=$targetId');
    controller.store.relationLookup[targetId] = oldRelation;
    controller.relationEngine.onRelationLayoutUpdated(targetId);
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
