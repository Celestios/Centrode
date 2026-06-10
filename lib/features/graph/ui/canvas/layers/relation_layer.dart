import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/graph_metrics.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/strategies/relation_layout_strategy.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../relation_painter.dart';
import '../canvas_text_editor.dart';
import '../../../presentation/routing/relation_layout_context.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataQuery>();
    final uiController = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();
    final theme = Theme.of(context);

    return Positioned.fill(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            uiController.movementNotifier,
            uiController,
            interactionController.state,
          ]),
          builder: (context, _) {
            final interactionState = interactionController.state.value;
            // Compute dragging overrides if a tip is actively being dragged
            final draggingOverrides = <String, (Offset, Offset)>{};
            if (interactionState is RelationTipDragging) {
              final drag = interactionState;
              UiRelation? rel;
              for (final r in dataController.relations) {
                if (r.id == drag.relationId) {
                  rel = r;
                  break;
                }
              }
              if (rel != null) {
                final from = uiController.viewStates[rel.fromNodeId];
                final to = uiController.viewStates[rel.toNodeId];
                if (from != null && to != null) {
                  final Offset dragPos;
                  if (drag.snappedTargetNodeId != null &&
                      drag.snappedTargetSide != null) {
                    final targetVs =
                        uiController.viewStates[drag.snappedTargetNodeId!];
                    dragPos = targetVs != null
                        ? targetVs.getPortPosition(drag.snappedTargetSide!)
                        : drag.currentCursorPosition;
                  } else {
                    dragPos = drag.currentCursorPosition;
                  }

                  final layoutStrategy = RelationLayoutStrategy.fromType(
                    rel.layout?.strategyType,
                  );
                  final (resolvedStart, resolvedEnd) = layoutStrategy
                      .resolveEndpoints(
                        rel,
                        from,
                        to,
                        overrideStart: drag.isStartTip ? dragPos : null,
                        overrideEnd: !drag.isStartTip ? dragPos : null,
                      );
                  draggingOverrides[rel.id] = (resolvedStart, resolvedEnd);
                }
              }
            }

            // Find if a relation is currently being edited
            final activeEditId = uiController.activeEditId;
            final editedRel = activeEditId != null
                ? dataController.relations
                      .where((r) => r.id == activeEditId)
                      .firstOrNull
                : null;

            Widget? editorWidget;
            final layoutContext = RelationLayoutContext(
              nodeViewStates: uiController.viewStates,
              relations: dataController.relations.toList(),
              pathCache: uiController.relationPathCache,
            );

            if (editedRel != null) {
              final fromVs = uiController.viewStates[editedRel.fromNodeId];
              final toVs = uiController.viewStates[editedRel.toNodeId];

              if (fromVs != null && toVs != null) {
                final layoutStrategy = RelationLayoutStrategy.fromType(
                  editedRel.layout?.strategyType,
                );
                final (start, end) = layoutStrategy.resolveEndpoints(
                  editedRel,
                  fromVs,
                  toVs,
                );

                final labelPos = layoutStrategy.computeLabelPosition(
                  start,
                  end,
                  fromVs,
                  toVs,
                  editedRel,
                  layoutContext,
                );

                final width = AppConfig.relation.editorMinWidth;
                final position =
                    labelPos -
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
                      content: ContentFactory.fromText(editedRel.verb),
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
                      uiController.viewStates,
                      uiController.selectedEntities,
                      pathCache: uiController.relationPathCache,
                      draggingOverrides: draggingOverrides,
                      interactionState: interactionState,
                      theme: theme,
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
