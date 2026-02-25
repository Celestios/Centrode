import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/graph_data_controller.dart';
import '../../../state/graph_ui_controller.dart';
import '../relation_painter.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final uiController = context.watch<GraphUIController>();

    return Positioned.fill(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: dataController.movementNotifier,
          builder: (context, _) {
            return CustomPaint(
              painter: RelationPainter(
                dataController.relations.toList(),
                dataController.allNodeViewStates,
                uiController.selectedEntities,
              ),
            );
          },
        ),
      ),
    );
  }
}
