import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../domain/models.dart';
import '../../domain/styling.dart';
import '../command_processor.dart';

import 'graph_store_mixin.dart';
import 'graph_sync_base_mixin.dart';

/// Property mutation operations for the graph sync hierarchy.
///
/// This mixin provides property-related mutation operations including:
/// - **commitEntityText**: Text changes for nodes and relations
/// - **updateNodeAesthetics**: Visual styling updates with snapshot/delta logic
///
/// ## Architecture
///
/// This mixin depends on [GraphSyncBaseMixin] for access to:
/// - [api]: FFI handle for Rust communication
/// - [processor]: Command processor for debounced writes
/// - [themeController]: Theme management for aesthetic defaults
/// - [onError]: Error callback for failure handling
///
/// ## Key Patterns
///
/// ### Debounced Text Updates
/// Text changes are queued via [CommandProcessor] with debouncing to
/// batch FFI calls during rapid typing.
///
/// ### Aesthetic Snapshot/Delta
/// When a node is first customized, a full snapshot is created from the
/// current theme. Subsequent edits merge deltas into the existing aesthetics.
///
/// See also:
/// - [GraphSyncBaseMixin] for the foundation infrastructure
/// - [GraphNodeMutationsMixin] for node operations
/// - [GraphRelationMutationsMixin] for relation operations
mixin GraphPropertyMutationsMixin
    on ChangeNotifier, GraphStoreMixin, GraphSyncBaseMixin {
  final Logger _propLog = Logger('GraphPropertyMutationsMixin');

  /// Commits text changes from inline editing with debounced write-behind sync.
  /// Handles both node text and relation labels with appropriate field mapping.
  void commitEntityText(String id, String newText) {
    final node = nodeLookup[id];
    final rel = relationLookup[id];
    final oldText = node?.text ?? rel?.label ?? "";

    // No change - skip
    if (newText == oldText) {
      return;
    }

    // Update Local Model optimistically
    if (node != null) {
      node.text = newText;
      if (node is InterUiNode) {
        node.verb = newText;
      }
    } else if (rel != null) {
      relationLookup[id] = UiRelation(
        id: rel.id,
        fromNodeId: rel.fromNodeId,
        toNodeId: rel.toNodeId,
        label: newText,
        color: rel.color,
      );
    }

    // Queue FFI Patch with debouncing
    processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node != null ? getTableName(node) : "relates_to",
        newText: newText,
        oldText: oldText,
        isRelation: rel != null,
        api: api,
        onUndo: () {
          // Rollback local state on FFI failure
          if (node != null) {
            node.text = oldText;
            if (node is InterUiNode) {
              node.verb = oldText;
            }
          } else if (rel != null) {
            relationLookup[id] = UiRelation(
              id: rel.id,
              fromNodeId: rel.fromNodeId,
              toNodeId: rel.toNodeId,
              label: oldText,
              color: rel.color,
            );
          }
        },
      ),
    );
  }

  /// Updates node aesthetics with snapshot/delta logic and debounced write-behind sync.
  ///
  /// This method routes aesthetic updates through the [CommandProcessor] to enable:
  /// - **Debouncing**: Rapid resizing or style changes are batched (300ms delay)
  /// - **Rollback**: Failed FFI calls automatically restore the previous aesthetics
  /// - **Composite Keys**: Aesthetic updates don't interfere with spatial/content commands
  ///
  /// The snapshot/delta logic ensures:
  /// 1. First customization creates a full snapshot from the current theme + updates
  /// 2. Subsequent edits merge updates into the existing aesthetics
  void updateNodeAesthetics(String id, StyleProfile updates) {
    final node = nodeLookup[id];
    if (node == null) return;

    // Capture old aesthetics for rollback before any modifications
    final oldAesthetics = node.aesthetics;

    StyleProfile finalAesthetics;
    final activeTheme = themeController.activeTheme;

    if (node.aesthetics == null && activeTheme != null) {
      // 1. First customization: Create a full snapshot from the current theme + updates
      final themeStyle =
          activeTheme.typeDefinitions[node.type.name.capitalize()] ??
          activeTheme.globalDefault;
      finalAesthetics = themeStyle.merge(updates);
      _propLog.info('Creating aesthetic snapshot for node $id');
    } else if (node.aesthetics != null) {
      // 2. Subsequent edits: Merge updates into existing aesthetics
      finalAesthetics = node.aesthetics!.merge(updates);
      _propLog.info('Merging aesthetic updates for node $id');
    } else {
      // Fallback
      finalAesthetics = updates;
    }

    // Update local model optimistically
    node.aesthetics = finalAesthetics;

    // Queue command with debouncing via CommandProcessor
    processor.queueCommand(
      UpdateAestheticsCommand(
        targetId: id,
        tableName: getTableName(node),
        newAesthetics: finalAesthetics,
        oldAesthetics: oldAesthetics,
        api: api,
        onUndo: () {
          // Rollback local state on FFI failure
          node.aesthetics = oldAesthetics;
          notifyListeners();
        },
      ),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
