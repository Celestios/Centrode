import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../store/graph_data_query.dart';
import '../../../state/graph_ui_controller.dart';
import '../node_widget.dart';

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.watch<GraphDataQuery>();
    final uiState = context.watch<GraphUIController>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: uiState.visibleNodeIds,
      builder: (context, visibleIds, _) {
        final renderStack = uiState.zOrder.where(visibleIds.contains);

        return Stack(
          clipBehavior: Clip.none,
          children: renderStack.map((id) {
            final node = query.nodeLookup[id]!;
            final viewState = query.viewStates[id]!;
            final isSelected = uiState.selectedEntities.contains(id);
            final isEditing = uiState.activeEditId == id;

            return Positioned(
              key: ValueKey(id),
              left: 0,
              top: 0,
              child: NodeWidget(
                viewState: viewState,
                node: node,
                isSelected: isSelected,
                isEditing: isEditing,
                isDeleteMenuVisible: uiState.nodeShowingDeleteMenu == id,
                onDelete: () => uiState.showDeleteMenu(id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
