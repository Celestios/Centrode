import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../presentation/graph_metrics.dart';
import '../../../store/graph_repository.dart';
import '../../../store/graph_data_query.dart';
import '../../../state/graph_ui_controller.dart';
import '../relation_painter.dart';
import '../canvas_text_editor.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataQuery>();
    final uiController = context.watch<GraphUIController>();

    return Positioned.fill(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: dataController.movementNotifier,
          builder: (context, _) {
            // Find if a relation is currently being edited
            final activeEditId = uiController.activeEditId;
            final editedRel = activeEditId != null
                ? dataController.relations
                      .where((r) => r.id == activeEditId)
                      .firstOrNull
                : null;

            Widget? editorWidget;
            if (editedRel != null) {
              final fromVs = dataController.viewStates[editedRel.fromNodeId];
              final toVs = dataController.viewStates[editedRel.toNodeId];

              if (fromVs != null && toVs != null) {
                final start = fromVs.rightPort;
                final end = toVs.leftPort;
                final mid = Offset(
                  (start.dx + end.dx) / 2,
                  (start.dy + end.dy) / 2,
                );

                final width = AppConfig.relation.editorMinWidth;
                final position =
                    mid -
                    Offset(width / 2, AppConfig.relation.editorVerticalOffset);

                editorWidget = Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: Container(
                    width: AppConfig.relation.editorMinWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.relation.editorBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppConfig.visuals.selectionAccent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CanvasTextEditor(
                      entityId: editedRel.id,
                      initialText: editedRel.verb,
                      maxLines: 1,
                      textStyle: TextStyle(
                        fontSize: AppConfig.editor.fontSizeRelation,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                );
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Base Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: RelationPainter(
                      dataController.relations.toList(),
                      dataController.viewStates,
                      uiController.selectedEntities,
                    ),
                  ),
                ),
                // Transient Inline Editor
                if (editorWidget != null) editorWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}
