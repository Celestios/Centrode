import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mycelium/src/rust/bridge/api.dart';

import 'nodes.dart';
import 'view_state.dart';
import 'spatial_index.dart';
import 'styling.dart';

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

/// Command for moving a node position with atomic rollback support.
/// Captures both the new position and the rollback position for error recovery.
class MoveNodeCommand implements GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final Offset newPosition;
  final Offset rollbackPosition;
  final NodeViewState nodeViewState;
  final SpatialHashGrid spatialGrid;
  final AppHandle api;
  final String tableName;

  /// Callback invoked on successful FFI sync to update canonical DB baseline.
  final VoidCallback onSuccess;

  /// Callback invoked on rollback to synchronize the domain model.
  final void Function(Offset) onUndo;

  MoveNodeCommand({
    required this.targetId,
    required this.newPosition,
    required this.rollbackPosition,
    required this.nodeViewState,
    required this.spatialGrid,
    required this.api,
    required this.tableName,
    required this.onSuccess,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.spatial;

  @override
  Future<void> execute() async {
    // Structural Refactor: Direct mapping to the Coordinates struct
    final patchJson = jsonEncode({
      "position": {
        "x": newPosition.dx.toInt(),
        "y": newPosition.dy.toInt(),
        "z": 0, // Assuming 2D canvas strictly uses Z=0 mapping
      },
    });

    await api.patchNodeProperties(
      table: tableName,
      id: targetId,
      jsonPatch: patchJson,
    );
  }

  @override
  void undo() {
    nodeViewState.positionNotifier.value = rollbackPosition;
    spatialGrid.update(targetId, newPosition, rollbackPosition);
    onUndo(rollbackPosition); // Synchronizes the Domain Model
  }
}

/// Command for deleting a node with rollback support.
/// Captures the node data for restoration on FFI failure.
class DeleteNodeCommand implements GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final AppHandle api;
  final String tableName;
  final UiNode nodeData;
  final void Function(UiNode) onUndo;
  final SpatialHashGrid spatialGrid;

  DeleteNodeCommand({
    required this.targetId,
    required this.api,
    required this.tableName,
    required this.nodeData,
    required this.onUndo,
    required this.spatialGrid,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.deleteNodeEntry(table: tableName, id: targetId);
  }

  @override
  void undo() {
    onUndo(nodeData);
    spatialGrid.insert(targetId, nodeData.position);
  }
}

/// Command for updating text content with debounced write-behind sync.
/// Handles both node text and relation labels with appropriate field mapping.
class UpdateTextCommand implements GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final String tableName;
  final String newText;
  final String oldText;
  final bool isRelation;
  final AppHandle api;
  final VoidCallback onUndo;

  UpdateTextCommand({
    required this.targetId,
    required this.tableName,
    required this.newText,
    required this.oldText,
    required this.isRelation,
    required this.api,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.content;

  @override
  Future<void> execute() async {
    final tName = isRelation ? "relates_to" : tableName;

    if (isRelation || tName == "inter_node") {
      // InterNodes and Relations mathematically rely on the scalar 'verb'
      // Relations still use JSON for verb field
      final patchJson = jsonEncode({"verb": newText});
      if (isRelation) {
        final String ffiId = targetId.contains(':')
            ? targetId
            : "$tName:$targetId";
        await api.patchRelation(id: ffiId, jsonPatch: patchJson);
      } else {
        await api.patchNodeProperties(
          table: tName,
          id: targetId,
          jsonPatch: patchJson,
        );
      }
    } else {
      // FIX: Bypass bincode on Dart side.
      // Rust's patch_node_content will receive raw bytes of the string.
      // We encode as UTF-8 directly to satisfy the Vec<u8> requirement
      final contentBytes = Uint8List.fromList(utf8.encode(newText));

      await api.patchNodeContent(
        table: tName,
        id: targetId,
        contentBytes: contentBytes,
      );
    }
  }

  @override
  void undo() {
    onUndo();
  }
}

/// Command for updating node aesthetics with rollback support.
/// Captures both the new and previous StyleProfile for error recovery.
class UpdateAestheticsCommand implements GraphCommand {
  @override
  String targetId; // Mutable to allow ID swapping for optimistic commands
  final String tableName;
  final StyleProfile newAesthetics;
  final StyleProfile? oldAesthetics;
  final AppHandle api;
  final VoidCallback onUndo;

  UpdateAestheticsCommand({
    required this.targetId,
    required this.tableName,
    required this.newAesthetics,
    required this.oldAesthetics,
    required this.api,
    required this.onUndo,
  });

  @override
  CommandCategory get category => CommandCategory.aesthetic;

  @override
  Future<void> execute() async {
    // Persist aesthetics to database as nested JSON string
    final patchJson = jsonEncode({
      "aesthetics": jsonEncode(newAesthetics.toJson()),
    });

    await api.patchNodeProperties(
      table: tableName,
      id: targetId,
      jsonPatch: patchJson,
    );
  }

  @override
  void undo() {
    onUndo();
  }
}
