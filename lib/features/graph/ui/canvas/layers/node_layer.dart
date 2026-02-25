import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/graph_data_controller.dart';
import '../../../state/graph_ui_controller.dart';
import '../node_widget.dart';

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final uiController = context.watch<GraphUIController>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: uiController.visibleNodeIds,
      builder: (context, visibleIds, _) {
        // BYPASS RESTORED: Chicken-and-Egg layout requires initial render for sizes.
        final nodeIds = visibleIds.isEmpty
            ? dataController.nodeLookup.keys.toList()
            : visibleIds.toList();

        final validNodeIds = nodeIds.where(
          (id) =>
              dataController.allNodeViewStates.containsKey(id) &&
              dataController.nodeLookup.containsKey(id),
        );

        // Sort IDs based on UI Controller's canonical Z-order
        final zOrderMap = <String, int>{};
        for (var i = 0; i < uiController.zOrder.length; i++) {
          zOrderMap[uiController.zOrder[i]] = i;
        }
        final sortedIds = validNodeIds.toList()
          ..sort((a, b) => (zOrderMap[a] ?? -1).compareTo(zOrderMap[b] ?? -1));

        return Stack(
          children: sortedIds.map((id) {
            final viewState = dataController.allNodeViewStates[id]!;
            final node = dataController.nodeLookup[id]!;

            return Positioned(
              key: ValueKey(id),
              left: 0,
              top: 0,
              child: NodeWidget(
                viewState: viewState,
                node: node,
                isDeleteMenuVisible:
                    uiController.nodeShowingDeleteMenu == node.id,
                onDelete: () => dataController.deleteNode(node.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
