import 'dart:ui';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/tags.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/contents.dart';

final _log = Logger('Commands');

// -----------------------------------------------------------------------------
// Command Pattern for State Mutations with Write-Behind Debouncing
// -----------------------------------------------------------------------------

/// Namespace categories for command debouncing.
/// Prevents different mutation types on the same node from overwriting each other
/// in the CommandProcessor's pending command map.
enum CommandCategory { spatial, content, aesthetic, lifecycle }

/// Abstract base class for all graph mutation commands.
/// Implements the Command Pattern for undoable operations with FFI sync.
abstract class GraphCommand {
  /// The ID of the entity being modified.
  /// Mutable to allow ID swapping for optimistic commands (temp ID → real DB ID).
  String targetId;

  /// Forced namespace for the debouncer to create composite keys.
  CommandCategory get category;

  /// Executes the command (typically an FFI call).
  Future<void> execute();

  /// Rolls back local state on FFI failure.
  void undo();

  GraphCommand({required this.targetId});
}

class MoveNodeCommand implements GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final Offset? oldPosition;
  final Offset? newPosition;
  final Size? oldSize;
  final Size? newSize;
  final NodeStyle? oldStyle;
  final NodeStyle? newStyle;
  final bool? oldExpanded;
  final bool? newExpanded;
  final VoidCallback onSuccess;
  final VoidCallback onUndo; // called on rollback

  MoveNodeCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldPosition,
    this.newPosition,
    this.oldSize,
    this.newSize,
    this.oldStyle,
    this.newStyle,
    this.oldExpanded,
    this.newExpanded,
    required this.onSuccess,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.spatial;

  @override
  Future<void> execute() async {
    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    if (newPosition != null && oldPosition != null) {
      forwardPatches.add(
        NodePatch.position(
          frb.Coordinates(
            x: newPosition!.dx.round(),
            y: newPosition!.dy.round(),
          ),
        ),
      );
      reversePatches.add(
        NodePatch.position(
          frb.Coordinates(
            x: oldPosition!.dx.round(),
            y: oldPosition!.dy.round(),
          ),
        ),
      );
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
    if (newStyle != null || oldStyle != null) {
      forwardPatches.add(NodePatch.style(newStyle));
      reversePatches.add(NodePatch.style(oldStyle));
    }
    if (newExpanded != null && oldExpanded != null) {
      forwardPatches.add(NodePatch.isExpanded(newExpanded!));
      reversePatches.add(NodePatch.isExpanded(oldExpanded!));
    }

    if (forwardPatches.isNotEmpty) {
      final patch = SymmetricEntityPatch(
        id: frb.RecordStrings(table: tableName, key: targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
    onSuccess();
  }

  @override
  void undo() {
    onUndo();
  }
}

/// Command for deleting a node with rollback support.
/// Captures the node data for restoration on FFI failure.
class DeleteNodeCommand implements GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final AppHandle api;
  final String tableName;
  final VoidCallback onUndo;

  DeleteNodeCommand({
    required this.targetId,
    required this.api,
    required this.tableName,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.deleteNodeEntry(table: tableName, key: targetId);
  }

  @override
  void undo() {
    onUndo();
  }
}

/// Command for updating text content with debounced write-behind sync.
/// Handles both node text and relation labels with appropriate field mapping.
class UpdateTextCommand implements GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final Content? oldContent;
  final Content? newContent;
  final Size? oldSize;
  final Size? newSize;
  final String? oldVerb;
  final String? newVerb;
  final VoidCallback onUndo;

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
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    if (tableName == 'IRelation') {
      final List<RelationPatch> forwardPatches = [];
      final List<RelationPatch> reversePatches = [];
      if (newVerb != null && oldVerb != null) {
        forwardPatches.add(RelationPatch.verb(newVerb!));
        reversePatches.add(RelationPatch.verb(oldVerb!));
      }
      if (forwardPatches.isNotEmpty) {
        final patch = SymmetricEntityPatch(
          id: frb.RecordStrings(table: tableName, key: targetId),
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
          id: frb.RecordStrings(table: tableName, key: targetId),
          forward: EntityPatch.node(forwardPatches),
          reverse: EntityPatch.node(reversePatches),
        );
        await api.applyEntityMutation(mutation: patch);
      }
    }
  }

  @override
  void undo() {
    onUndo();
  }
}

class CreateNodeCommand implements GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiNode node;
  final VoidCallback onUndo;

  CreateNodeCommand({
    required this.targetId,
    required this.api,
    required this.node,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.createNode(input: node.toRust());
  }

  @override
  void undo() {
    onUndo();
  }
}

class CreateRelationCommand implements GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiRelation relation;
  final Future<void> Function() reloadGraph;
  final VoidCallback? onUndo;

  CreateRelationCommand({
    required this.targetId,
    required this.api,
    required this.relation,
    required this.reloadGraph,
    this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    try {
      _log.info('Executing CreateRelationCommand for $targetId');
      await api.createRelation(input: relation.toRust());
      _log.info('Calling reloadGraph...');
      await reloadGraph();
      _log.info('Executed CreateRelationCommand successfully.');
    } catch (e, st) {
      _log.severe('CreateRelationCommand FAILED: $e', e, st);
      rethrow;
    }
  }

  @override
  void undo() {
    onUndo?.call();
  }
}

class DeleteRelationCommand implements GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final String tableName;
  final VoidCallback onUndo;

  DeleteRelationCommand({
    required this.targetId,
    required this.api,
    required this.tableName,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.deleteRelation(table: tableName, key: targetId);
  }

  @override
  void undo() {
    onUndo();
  }
}

class UpdateRelationLayoutCommand implements GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final RelationLayout? oldLayout;
  final RelationLayout? newLayout;
  final RelationStyle? oldStyle;
  final RelationStyle? newStyle;
  final VoidCallback onUndo;

  UpdateRelationLayoutCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldLayout,
    this.newLayout,
    this.oldStyle,
    this.newStyle,
    required this.onUndo,
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
    onUndo();
  }
}

class UpdateTagsCommand implements GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final List<Tag> oldTags;
  final List<Tag> newTags;
  final void Function(List<Tag> resolvedTags) onSuccess;
  final VoidCallback onUndo;

  UpdateTagsCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    required this.oldTags,
    required this.newTags,
    required this.onSuccess,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    final allTags = await api.getAllTags();
    final Map<String, Tag> nameToTag = {
      for (final t in allTags) t.fields.name.toLowerCase(): t
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

    final oldLowerNames = oldTags.map((t) => t.fields.name.toLowerCase()).toSet();
    final newLowerNames = resolvedNewTags.map((t) => t.fields.name.toLowerCase()).toSet();

    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    // Tags that are truly new (their lowercase name is in resolvedNewTags but not in oldTags)
    final added = resolvedNewTags.where((t) => !oldLowerNames.contains(t.fields.name.toLowerCase())).toList();
    // Tags that are truly removed (their lowercase name is in oldTags but not in resolvedNewTags)
    final removed = oldTags.where((t) => !newLowerNames.contains(t.fields.name.toLowerCase())).toList();

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
        id: frb.RecordStrings(table: tableName, key: targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }

    onSuccess(resolvedNewTags);
  }

  @override
  void undo() {
    onUndo();
  }
}

class UpdateCommentsCommand implements GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final UiNode node;
  final VoidCallback onUndo;

  UpdateCommentsCommand({
    required this.targetId,
    required this.api,
    required this.node,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    await api.updateNode(input: node.toRust());
  }

  @override
  void undo() {
    onUndo();
  }
}

class UpdateNodeStyleCommand implements GraphCommand {
  @override
  String targetId;
  final String tableName;
  final AppHandle api;
  final NodeStyle? oldStyle;
  final NodeStyle? newStyle;
  final Size? oldSize;
  final Size? newSize;
  final void Function() onUndo;

  UpdateNodeStyleCommand({
    required this.targetId,
    required this.tableName,
    required this.api,
    this.oldStyle,
    this.newStyle,
    this.oldSize,
    this.newSize,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    final List<NodePatch> forwardPatches = [];
    final List<NodePatch> reversePatches = [];

    if (newStyle != null || oldStyle != null) {
      forwardPatches.add(NodePatch.style(newStyle));
      reversePatches.add(NodePatch.style(oldStyle));
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
        id: frb.RecordStrings(table: tableName, key: targetId),
        forward: EntityPatch.node(forwardPatches),
        reverse: EntityPatch.node(reversePatches),
      );
      await api.applyEntityMutation(mutation: patch);
    }
  }

  @override
  void undo() {
    onUndo();
  }
}
