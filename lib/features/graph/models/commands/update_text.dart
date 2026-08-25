import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/src/rust/domain/contents.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

final Logger _log = Logger('UpdateTextCommand');

/// Command for updating text content with debounced write-behind sync.
/// Handles both node text and relation labels with appropriate field mapping.
class UpdateTextCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final String tableName;
  final NodeApi api;
  final Content? oldContent;
  final Content? newContent;
  final Size? oldSize;
  final Size? newSize;
  final String? oldVerb;
  final String? newVerb;
  final GraphCommandContext controller;

  UpdateTextCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldContent,
    this.newContent,
    this.oldSize,
    this.newSize,
    this.oldVerb,
    this.newVerb,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    _log.info('execute UpdateText key=$targetId table=$tableName');
    if (tableName == 'IRelation') {
      final List<RelationPatch> forwardPatches = [];
      final List<RelationPatch> reversePatches = [];
      if (newVerb != null && oldVerb != null) {
        forwardPatches.add(RelationPatch.verb(newVerb!));
        reversePatches.add(RelationPatch.verb(oldVerb!));
      }
      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: parseTypedRecordId(tableName, targetId),
          forward: EntityPatch.relation(forwardPatches),
          reverse: EntityPatch.relation(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    } else {
      final List<NodePatch> forwardPatches = [];
      final List<NodePatch> reversePatches = [];
      if (newContent != null && oldContent != null) {
        forwardPatches.add(NodePatch.content(newContent!));
        reversePatches.add(NodePatch.content(oldContent!));
      }
      if (newSize != null && oldSize != null) {
        forwardPatches.add(
          NodePatch.size(
            frb.Size(
              width: newSize!.width.round(),
              height: newSize!.height.round(),
            ),
          ),
        );
        reversePatches.add(
          NodePatch.size(
            frb.Size(
              width: oldSize!.width.round(),
              height: oldSize!.height.round(),
            ),
          ),
        );
      }
      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: parseTypedRecordId(tableName, targetId),
          forward: EntityPatch.node(forwardPatches),
          reverse: EntityPatch.node(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateText key=$targetId');
    final node = controller.store.nodeLookup[targetId];
    final rel = controller.store.relationLookup[targetId];

    if (node != null) {
      if (oldContent != null) {
        node.content = oldContent!;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: node.tableName,
            type: GraphUpdateType.text,
            payload: oldContent!.text,
          ),
        );
      }
      if (oldSize != null) {
        node.size = oldSize!;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: node.tableName,
            type: GraphUpdateType.size,
            payload: oldSize,
          ),
        );
      }
    } else if (rel != null) {
      if (oldVerb != null) {
        rel.verb = oldVerb!;
        controller.publishUpdate(
          GraphEntityUpdate(
            id: targetId,
            tableName: 'IRelation',
            type: GraphUpdateType.text,
            payload: oldVerb,
          ),
        );
      }
    }
  }
}
