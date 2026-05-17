import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';

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
  final UiNode newNode; // node with updated position
  final AppHandle api;
  final VoidCallback onSuccess;
  final VoidCallback onUndo; // called on rollback

  MoveNodeCommand({
    required this.targetId,
    required this.newNode,
    required this.api,
    required this.onSuccess,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.spatial;

  @override
  Future<void> execute() async {
    await api.updateNode(input: newNode.toRust());
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
  final AppHandle api;
  final UiNode? newNode; // snapshot with new content
  final UiRelation? newRelation; // snapshot with new verb
  final VoidCallback onUndo; // extra rollback work if needed

  UpdateTextCommand({
    required this.targetId,
    required this.api,
    this.newNode,
    this.newRelation,
    required this.onUndo,
  }) : assert(
         newNode != null || newRelation != null,
         'Must provide either node or relation',
       );

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    if (newNode != null) {
      await api.updateNode(input: newNode!.toRust());
    } else if (newRelation != null) {
      await api.updateRelation(input: newRelation!.toRust());
    }
  }

  @override
  void undo() {
    onUndo(); // caller restores the old text/verb
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

  CreateRelationCommand({
    required this.targetId,
    required this.api,
    required this.relation,
    required this.reloadGraph,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.createRelation(input: relation.toRust());
    await reloadGraph();
  }

  @override
  void undo() {
    // Pessimistic creation doesn't have an optimistic local state to undo.
  }
}
