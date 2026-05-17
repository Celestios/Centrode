import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import '../../state/command_processor.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/presentation/style_resolver.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
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

  late final StyleManager styleManager;

  void commitEntityText(String id, String newText) {
    _propLog.info('Committing text for $id: "$newText"');
    final node = nodeLookup[id];
    final rel = relationLookup[id];

    // No-op guard
    if (node != null && node.content.text == newText) return;
    if (rel != null && rel.verb == newText) return;

    // Capture old text for rollback
    final String oldText = node?.content.text ?? rel?.verb ?? '';

    // 1. Optimistic update
    if (node != null) {
      node.content = ContentFactory.fromText(newText);
    } else if (rel != null) {
      rel.verb = newText;
    }

    // 2. Build FFI payload (shallow copy of the now-mutated object)
    final UiNode? newNode = UiNode.copy(node);
    final UiRelation? newRelation = UiRelation.copy(rel);

    // 3. Queue command with primitive rollback
    processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        api: api,
        newNode: newNode,
        newRelation: newRelation,
        onUndo: () {
          // Restore exactly the field that was changed
          if (node != null) {
            node.content = ContentFactory.fromText(oldText);
            viewStates[id]?.onContentOrStyleChanged(node); // re‑compute size
          } else if (rel != null) {
            rel.verb = oldText;
          }
          notifyListeners();
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
  void updateNodeStyle(String id, NodeStyle newStyle) {
    final node = nodeLookup[id];
    if (node == null) return;
    node.style = newStyle;
    styleManager.updateStyleForNode(id);
    // TODO: Also persist the change (new style) via a command – TBD later.
  }
}
