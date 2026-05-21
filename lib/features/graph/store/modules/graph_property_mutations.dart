import 'dart:ui';
import 'package:logging/logging.dart';
import '../../models/models.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import '../../presentation/strategies/node_layout_strategy.dart';
import '../graph_data_controller.dart';

/// Property mutation operations for the graph.
class GraphPropertyMutations {
  final Logger _propLog = Logger('GraphPropertyMutations');
  final GraphDataController controller;

  GraphPropertyMutations(this.controller);

  void commitEntityText(String id, String newText, {String? originalText}) {
    _propLog.info('Committing text for $id: "$newText" (original: "$originalText")');
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    // Determine the pre-edited state to check for changes and configure rollbacks
    final String effectiveOriginalText = originalText ?? (node?.content.text ?? rel?.verb ?? '');
    
    // If the text didn't actually change from the original starting text, no-op
    if (effectiveOriginalText == newText) return;

    // Capture the pre-edit size of the node (before any live keystroke resizing occurred)
    Size? preEditSize;
    if (node != null && originalText != null) {
      final oldContent = node.content;
      node.content = ContentFactory.fromText(originalText);
      preEditSize = NodeLayoutStrategy.calculateSize(node);
      // Restore back to current text
      node.content = oldContent;
    } else {
      preEditSize = node?.size;
    }

    // 1. Ensure the optimistic memory state is completely up-to-date
    if (node != null) {
      node.content = ContentFactory.fromText(newText);
      node.size = NodeLayoutStrategy.calculateSize(node);
    } else if (rel != null) {
      rel.verb = newText;
    }

    // 3. Queue command with primitive rollback
    controller.syncEngine.processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node?.tableName ?? 'IRelation',
        api: controller.syncEngine.api,
        oldContent: node == null ? null : ContentFactory.fromText(effectiveOriginalText),
        newContent: node == null ? null : ContentFactory.fromText(newText),
        oldSize: node == null ? null : preEditSize,
        newSize: node?.size,
        oldVerb: rel == null ? null : effectiveOriginalText,
        newVerb: rel == null ? null : newText,
        onUndo: () {
          // Restore exactly the field and dimensions that were changed
          if (node != null) {
            node.content = ContentFactory.fromText(effectiveOriginalText);
            if (preEditSize != null) {
              node.size = preEditSize;
            }
          } else if (rel != null) {
            rel.verb = effectiveOriginalText;
          }
          controller.triggerUpdate();
        },
      ),
    );
    controller.triggerUpdate();
  }

  /// Updates the entity text locally in memory without triggering FFI/database sync.
  /// This is used for buttery smooth, real-time visual canvas resizing as the user types.
  void updateEntityTextLive(String id, String newText) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    if (node != null) {
      if (node.content.text == newText) return;
      node.content = ContentFactory.fromText(newText);
      node.size = NodeLayoutStrategy.calculateSize(node);
      controller.triggerUpdate();
    } else if (rel != null) {
      if (rel.verb == newText) return;
      rel.verb = newText;
      controller.triggerUpdate();
    }
  }

  /// Updates node aesthetics with snapshot/delta logic and debounced write-behind sync.
  void updateNodeStyle(String id, NodeStyle newStyle) {
    final node = controller.store.nodeLookup[id];
    if (node == null) return;
    node.style = newStyle;
    controller.styleManager.updateStyleForNode(id);
    // TODO: Also persist the change (new style) via a command – TBD later.
  }
}
