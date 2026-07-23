import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/view_state.dart';
import '../painters/drawing_node_painter.dart';

class DrawNodeWidget extends StatelessWidget {
  final DrawingUiNode node;
  final NodeViewState viewState;
  final bool isSelected;
  final bool isEditing;

  const DrawNodeWidget({
    super.key,
    required this.node,
    required this.viewState,
    required this.isSelected,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final liveNode = context.select<GraphDataQuery, DrawingUiNode>(
      (c) => (c.nodeLookup[node.id] ?? node) as DrawingUiNode,
    );

    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.sizeNotifier,
        viewState.dragWidthNotifier,
      ]),
      builder: (context, _) {
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: size,
              painter: DrawingNodePainter(
                brushColor: liveNode.brushColor,
                brushThickness: liveNode.brushThickness,
                brushType: liveNode.brushType.name,
                paths: liveNode.paths,
                parsedPaths: liveNode.parsedPaths,
              ),
            ),
          ],
        );
      },
    );
  }
}
