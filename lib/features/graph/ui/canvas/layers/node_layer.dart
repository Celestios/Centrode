import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../store/graph_data_query.dart';
import '../../../models/models.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/viewport_state.dart';
import '../node_widget.dart';

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.read<GraphDataQuery>();
    final uiState = context.watch<NodeRenderState>();
    final viewport = context.read<ViewportController>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: viewport.visibleNodeIds,
      builder: (context, visibleIds, _) {
        final renderStack = uiState.zOrder.where(visibleIds.contains);

        return Stack(
          clipBehavior: Clip.none,
          children: renderStack.map((id) {
            final node = query.nodeLookup[id]!;
            final viewState = uiState.viewStates[id]!;
            final isSelected = uiState.selectedEntities.contains(id);
            final isEditing = uiState.activeEditId == id;

            return ListenableBuilder(
              listenable: viewState.positionNotifier,
              builder: (context, _) {
                final pos = viewState.positionNotifier.value;
                return Positioned(
                  key: ValueKey(id),
                  left: pos.dx,
                  top: pos.dy,
                  child: RepaintBoundary(
                    child: switch (node) {
                      DrawingUiNode drawingNode => DrawNodeWidget(
                        viewState: viewState,
                        node: drawingNode,
                        isSelected: isSelected,
                        isEditing: isEditing,
                      ),
                      _ => NodeWidget(
                        viewState: viewState,
                        node: node,
                        isSelected: isSelected,
                        isEditing: isEditing,
                      ),
                    },
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
