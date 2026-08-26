import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../widgets/metadata_preview_overlay.dart';
import '../widgets/relation_label_morph_editor.dart';
import '../../../presentation/relation_label_suggestion_controller.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import '../painters/temp_relation_painter.dart';
import '../painters/marquee_painter.dart';
import '../painters/opt_area_painter.dart';
import '../painters/persistent_opt_area_painter.dart';
import '../painters/frame_drawing_painter.dart';

export '../painters/temp_relation_painter.dart';
export '../painters/marquee_painter.dart';
export '../painters/opt_area_painter.dart';
export '../painters/persistent_opt_area_painter.dart';
export '../painters/frame_drawing_painter.dart';

class OverlayLayer extends StatelessWidget {
  const OverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataQuery>();
    final renderState = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();

    return ValueListenableBuilder<CanvasInteractionState>(
      valueListenable: interactionController.state,
      builder: (context, interactionState, _) {
        return UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            // 1. Temporary Relation Drag Line
            if (interactionState is RelationDrawing)
              Positioned.fill(
                child: ValueListenableBuilder<int>(
                  valueListenable: dataController.relationEngine.cacheNotifier,
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: TempRelationPainter(
                        state: interactionState,
                        nodeViewStates: renderState.viewStates,
                        relationEngine: dataController.relationEngine,
                      ),
                    );
                  },
                ),
              ),

            // 2. Marquee Selection Box Layer
            if (interactionState is MarqueeSelecting)
              Positioned.fill(
                child: CustomPaint(
                  painter: MarqueePainter(state: interactionState),
                ),
              ),

            // 3. Persistent OptArea Box Layer
            ValueListenableBuilder<Rect?>(
              valueListenable: dataController.optAreaNotifier,
              builder: (context, persistentOptRect, _) {
                if (persistentOptRect == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: CustomPaint(
                    painter: PersistentOptAreaPainter(rect: persistentOptRect),
                  ),
                );
              },
            ),

            // 4. OptArea Drawing Box Layer
            if (interactionState is OptAreaDrawing)
              Positioned.fill(
                child: CustomPaint(
                  painter: OptAreaPainter(state: interactionState),
                ),
              ),

            // 5. Frame Drawing Live Box Layer
            if (interactionState is FrameDrawing)
              Positioned.fill(
                child: CustomPaint(
                  painter: FrameDrawingPainter(state: interactionState),
                ),
              ),

            // 6. Metadata Preview Overlay Card
            ListenableBuilder(
              listenable: renderState.hoveredNodeMetadataNotifier,
              builder: (context, _) {
                final hoveredNodeId =
                    renderState.hoveredNodeMetadataNotifier.value;
                if (hoveredNodeId == null) return const SizedBox.shrink();

                final node = dataController.nodeLookup[hoveredNodeId];
                final vs = renderState.viewStates[hoveredNodeId];
                if (node is! InfoUiNode || vs == null) {
                  return const SizedBox.shrink();
                }

                final rect = vs.rect;
                return Positioned(
                  left: rect.left,
                  top: rect.bottom + 8,
                  child: MetadataPreviewOverlay(
                    node: node,
                    nodeWidth: rect.width,
                  ),
                );
              },
            ),

            // 7. Morphing Relation Label Inline Editor Overlay
            ListenableBuilder(
              listenable: renderState.editorState,
              builder: (context, _) {
                final activeEditId = renderState.editorState.activeEditId;
                if (activeEditId == null) return const SizedBox.shrink();

                final relation = dataController.relationLookup[activeEditId];
                if (relation == null) return const SizedBox.shrink();

                final interactionContext =
                    context.read<InteractionController>().environment;
                final tabsController = context.read<WorkspaceTabsController>();
                final activeSession = tabsController.activeSession;

                final cached = dataController.relationEngine.cache[activeEditId];
                final labelCenter = cached != null
                    ? Offset(cached.labelPosition.x, cached.labelPosition.y)
                    : Offset.zero;

                final suggestionController = RelationLabelSuggestionController(
                  api: activeSession.mlApi,
                  queryController: dataController,
                  relation: relation,
                );

                return RelationLabelMorphEditor(
                  relation: relation,
                  labelCenter: labelCenter,
                  suggestionController: suggestionController,
                  uiController: renderState,
                  interactionContext: interactionContext,
                  onCommit: (verb) {
                    activeSession.commandProcessor.commitEntityText(activeEditId, verb);
                    renderState.editorState.cancelActiveEdit();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
