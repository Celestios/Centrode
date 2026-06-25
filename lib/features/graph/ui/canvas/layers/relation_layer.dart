import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_controller.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/strategies/relation_layout_strategy.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../painters/relation_painter.dart';
import '../text/canvas_text_editor.dart';
import '../../../presentation/routing/relation_layout_context.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';

class RelationLayer extends StatelessWidget {
  RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataController>();
    final uiController = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ListenableBuilder(
          listenable: Listenable.merge([
            uiController.movementNotifier,
            uiController.selectionState,
            uiController.relationDataNotifier,
            uiController.editorState,
            interactionController.state,
            dataController.relationEngine.cacheNotifier,
          ]),
          builder: (context, _) {
            final interactionState = interactionController.state.value;

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

            return UnboundedStack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: RelationPainter(
                        dataController.relations.toList(),
                        uiController.viewStates,
                        uiController.selectedEntities,
                        pathCache: uiController.relationPathCache,
                        relationEngine: dataController.relationEngine,
                        interactionState: interactionState,
                        theme: theme,
                      ),
                    ),
                  ),
                ),
                if (editorWidget != null) editorWidget,
              ],
            );
          },
        ),
      );
  }
}
