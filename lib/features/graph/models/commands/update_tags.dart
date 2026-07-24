import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/src/rust/domain/types.dart';
import 'package:mycelium/src/rust/domain/patches.dart';
import '../../store/graph_api.dart';
import '../../store/graph_data_query.dart';
import '../graph_node.dart';
import 'base.dart';
import 'graph_command_context.dart';
import 'patch_helpers.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

final Logger _log = Logger('UpdateTagsCommand');

class UpdateTagsCommand extends GraphCommand {
  @override
  RawUuid targetId;
  final String tableName;
  final GraphApi api;
  final List<Tag> oldTags;
  final List<Tag> newTags;
  final GraphCommandContext controller;
  List<Tag>? _resolvedNewTags;

  UpdateTagsCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    required this.oldTags,
    required this.newTags,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    _log.info('execute UpdateTags key=$targetId old=${oldTags.length} new=${newTags.length}');
    final allTags = await api.getAllTags();
    final Map<String, Tag> nameToTag = {
      for (final t in allTags) t.fields.name.toLowerCase(): t,
    };

    final List<Tag> resolvedNewTags = [];
    for (final tag in newTags) {
      final existing = nameToTag[tag.fields.name.toLowerCase()];
      if (existing == null) {
        await api.createTag(tag: tag);
        resolvedNewTags.add(tag);
        nameToTag[tag.fields.name.toLowerCase()] = tag;
      } else {
        resolvedNewTags.add(existing);
      }
    }

    final oldLowerNames = oldTags
        .map((t) => t.fields.name.toLowerCase())
        .toSet();
    final newLowerNames = resolvedNewTags
        .map((t) => t.fields.name.toLowerCase())
        .toSet();

    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    // Tags that are truly new (their lowercase name is in resolvedNewTags but not in oldTags)
    final added = resolvedNewTags
        .where((t) => !oldLowerNames.contains(t.fields.name.toLowerCase()))
        .toList();
    // Tags that are truly removed (their lowercase name is in oldTags but not in resolvedNewTags)
    final removed = oldTags
        .where((t) => !newLowerNames.contains(t.fields.name.toLowerCase()))
        .toList();

    for (final tag in added) {
      forwardPatches.add(NodePatch.tagOp(TagOperation.add(tag.key)));
      reversePatches.add(NodePatch.tagOp(TagOperation.remove(tag.key)));
    }

    for (final tag in removed) {
      forwardPatches.add(NodePatch.tagOp(TagOperation.remove(tag.key)));
      reversePatches.add(NodePatch.tagOp(TagOperation.add(tag.key)));
    }

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: parseTypedRecordId(tableName, targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }

    _resolvedNewTags = resolvedNewTags;
  }

  @override
  void onSuccess() {
    final node = controller.store.nodeLookup[targetId];
    if (node is InfoUiNode && _resolvedNewTags != null) {
      node.tags = _resolvedNewTags!;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.tags,
          payload: _resolvedNewTags!,
        ),
      );
      controller.triggerUpdate();
    }
  }

  @override
  void undo() {
    _log.info('undo UpdateTags key=$targetId restoring ${oldTags.length} tags');
    final node = controller.store.nodeLookup[targetId];
    if (node is InfoUiNode) {
      node.tags = oldTags;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: targetId,
          tableName: tableName,
          type: GraphUpdateType.tags,
          payload: oldTags,
        ),
      );
      controller.triggerUpdate();
    }
  }
}
