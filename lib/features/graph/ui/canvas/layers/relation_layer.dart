import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_query_controller.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import '../../../presentation/viewport_state.dart';
import '../../../presentation/strategies/node_layout_strategy.dart';
import '../painters/relation_painter.dart';
import '../painters/relation_painter_dto.dart';
import '../painters/relation_paint_dto_builder.dart';
import '../painters/transformed_relation_painter.dart';
import '../text/canvas_text_editor.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final queryController = context.read<GraphDataQueryController>();
    final uiController = context.read<NodeRenderState>();
    final interactionController = context.read<InteractionController>();
    final viewport = context.read<ViewportController>();
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          uiController.movementNotifier,
          uiController.selectionState,
          uiController.relationDataNotifier,
          uiController.editorState,
          interactionController.state,
          queryController.relationEngine.cacheNotifier,
          session.relationLabelModeNotifier,
          viewport.activeScopeNotifier,
        ]),
        builder: (context, _) {
          final interactionState = interactionController.state.value;

          final activeEditId = uiController.activeEditId;
          final editedRel = activeEditId != null
              ? queryController.relations
                    .where((r) => r.id == activeEditId)
                    .firstOrNull
              : null;

          Widget? editorWidget;

          if (editedRel != null) {
            final cached = queryController.relationEngine.cache[editedRel.id];
            if (cached != null) {
              final labelPos = Offset(
                cached.labelPosition.x,
                cached.labelPosition.y,
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
                      color: AppThemeManager.instance.currentTheme.canvasAccentColor,
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

          final activeScope = viewport.activeScopeNotifier.value;
          final scopeRelations = queryController.relationsInScope(activeScope);

          final paintDtos = RelationPaintDtoBuilder.buildPaintDtos(
            relations: scopeRelations,
            nodeViewStates: uiController.viewStates,
            selectedEntities: uiController.selectedEntities,
            relationEngine: queryController.relationEngine,
            interactionState: interactionState,
            labelMode: session.relationLabelModeNotifier.value,
            theme: theme,
          );

          List<RelationPaintDto> outsidePaintDtos = const [];
          double outsideScaleX = 1.0;
          double outsideScaleY = 1.0;
          Offset outsideOriginOffset = Offset.zero;

          if (activeScope is ContainerViewportScope) {
            final parentContainer =
                queryController.nodeLookup[activeScope.containerId] as ContainerUiNode?;
            final containerVs = uiController.viewStates[activeScope.containerId];
            final effectiveOuterSize = (containerVs != null &&
                    containerVs.sizeNotifier.value.width > 0 &&
                    containerVs.sizeNotifier.value.height > 0)
                ? Size(
                    containerVs.dragWidthNotifier.value ??
                        containerVs.sizeNotifier.value.width,
                    containerVs.sizeNotifier.value.height,
                  )
                : (activeScope.outerSize.width > 0 && activeScope.outerSize.height > 0)
                    ? activeScope.outerSize
                    : (parentContainer != null)
                        ? const DefaultNodeLayoutStrategy()
                            .calculateSize(parentContainer)
                            .size
                        : const Size(300.0, 180.0);
            outsideOriginOffset = containerVs?.positionNotifier.value ??
                parentContainer?.position ??
                activeScope.containerPositionInParent;
            final aspectRatio = effectiveOuterSize.height /
                (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
            final internalW = 1600.0;
            final internalH = 1600.0 * aspectRatio;
            outsideScaleX = internalW /
                (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
            outsideScaleY = internalH /
                (effectiveOuterSize.height > 0 ? effectiveOuterSize.height : 1.0);

            final parentScope = activeScope.parentScope ?? const RootViewportScope();
            final outsideRelations = queryController.relationsInScope(parentScope);
            outsidePaintDtos = RelationPaintDtoBuilder.buildPaintDtos(
              relations: outsideRelations,
              nodeViewStates: uiController.viewStates,
              selectedEntities: uiController.selectedEntities,
              relationEngine: queryController.relationEngine,
              interactionState: interactionState,
              labelMode: session.relationLabelModeNotifier.value,
              theme: theme,
            );
          }

          return UnboundedStack(
            clipBehavior: Clip.none,
            children: [
              if (outsidePaintDtos.isNotEmpty)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: TransformedRelationPainter(
                        paintDtos: outsidePaintDtos,
                        theme: theme,
                        scaleX: outsideScaleX,
                        scaleY: outsideScaleY,
                        originOffset: outsideOriginOffset,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: RelationPainter(
                      paintDtos: paintDtos,
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
