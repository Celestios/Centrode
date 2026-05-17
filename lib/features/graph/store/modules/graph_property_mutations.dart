import 'package:logging/logging.dart';
import '../../models/models.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import '../graph_data_controller.dart';

/// Property mutation operations for the graph.
class GraphPropertyMutations {
  final Logger _propLog = Logger('GraphPropertyMutations');
  final GraphDataController controller;

  GraphPropertyMutations(this.controller);

  void commitEntityText(String id, String newText) {
    _propLog.info('Committing text for $id: "$newText"');
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

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
    controller.syncEngine.processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        api: controller.syncEngine.api,
        newNode: newNode,
        newRelation: newRelation,
        onUndo: () {
          // Restore exactly the field that was changed
          if (node != null) {
            node.content = ContentFactory.fromText(oldText);
          } else if (rel != null) {
            rel.verb = oldText;
          }
          controller.triggerUpdate();
        },
      ),
    );
    controller.triggerUpdate();
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
