import 'package:flutter/material.dart';
import '../../store/graph_data_query_controller.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/drawing_interceptor.dart';
import '../../presentation/workspace_tabs_controller.dart';
import '../../models/models.dart';
import '../widgets/overlays/canvas_tool_ribbon.dart';
import '../widgets/overlays/canvas_tab_bar.dart';
import '../widgets/overlays/left_repository_drawer.dart';
import '../widgets/overlays/right_property_panel.dart';
import '../widgets/overlays/canvas_status_bar/canvas_status_bar.dart';
import 'context_toolbar_overlay.dart';
import 'package:mycelium/features/graph/ui/widgets/tag_manager/global_tags_manager_panel.dart';
import 'package:mycelium/features/graph/ui/widgets/template_manager/global_templates_manager_panel.dart';
import 'package:mycelium/features/graph/ui/widgets/drawing_manager/global_drawing_panel.dart';

class CanvasOverlayLayout extends StatelessWidget {
  final BoxConstraints constraints;
  final NodeRenderState renderState;
  final GraphDataQueryController queryController;
  final InteractionController interactionController;
  final ViewportController viewportController;
  final TabSession session;
  final DrawingGestureInterceptor? drawingInterceptor;

  const CanvasOverlayLayout({
    super.key,
    required this.constraints,
    required this.renderState,
    required this.queryController,
    required this.interactionController,
    required this.viewportController,
    required this.session,
    this.drawingInterceptor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 52.0,
          left: 16.0,
          right: 16.0,
          child: RepaintBoundary(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const CanvasToolRibbon(),
                const SizedBox(width: 8),
                const Flexible(child: CanvasTabBar()),
              ],
            ),
          ),
        ),

        Positioned(
          top: 112.0,
          left: 12,
          width: 52,
          child: ValueListenableBuilder<bool>(
            valueListenable: session.showLeftPanel,
            builder: (context, leftVisible, _) {
              if (!leftVisible) return const SizedBox.shrink();
              return ValueListenableBuilder<LeftPanelType>(
                valueListenable: renderState.activeLeftPanelNotifier,
                builder: (context, activeLeftPanel, _) {
                  return LeftRepositoryDrawer(
                    activePanel: activeLeftPanel,
                    onPanelChanged: (panel) {
                      renderState.activeLeftPanelNotifier.value = panel;
                      if (panel == LeftPanelType.draw) {
                        session.setToolMode('draw');
                      } else {
                        session.setToolMode('select');
                      }
                    },
                  );
                },
              );
            },
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable: session.showLeftPanel,
          builder: (context, leftVisible, _) {
            return ValueListenableBuilder<LeftPanelType>(
              valueListenable: renderState.activeLeftPanelNotifier,
              builder: (context, activeLeftPanel, _) {
                final isOpen = activeLeftPanel != LeftPanelType.none;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  top: 112.0,
                  left: leftVisible ? 76.0 : -300.0,
                  width: (leftVisible && isOpen) ? 280.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: (leftVisible && isOpen) ? 1.0 : 0.0,
                    child: ClipRect(
                      child: UnconstrainedBox(
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.hardEdge,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 280.0,
                            maxWidth: 280.0,
                            minHeight: 180,
                            maxHeight:
                                (constraints.maxHeight - 112 - 86)
                                    .clamp(180, 10000)
                                    .toDouble(),
                          ),
                          child: _buildLeftPanelContent(
                            activeLeftPanel,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        Positioned(
          top: 112.0,
          right: 12,
          child: ValueListenableBuilder<bool>(
            valueListenable: session.showRightPanel,
            builder: (context, visible, _) {
              if (!visible) return const SizedBox.shrink();
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 180,
                  maxHeight: (constraints.maxHeight - 112 - 224)
                      .clamp(180, 10000)
                      .toDouble(),
                ),
                child: const RightPropertyPanel(),
              );
            },
          ),
        ),

        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: ValueListenableBuilder<bool>(
            valueListenable: session.showBottomPanel,
            builder: (context, visible, _) {
              if (!visible) return const SizedBox.shrink();
              return const CanvasStatusBar();
            },
          ),
        ),

        if (renderState.selectedEntities.isNotEmpty)
          ContextToolbarOverlay(
            renderState: renderState,
            queryController: queryController,
            interactionContext: interactionController.environment,
            viewportController: viewportController,
            interactionController: interactionController,
          ),
      ],
    );
  }

  Widget _buildLeftPanelContent(LeftPanelType activePanel) {
    switch (activePanel) {
      case LeftPanelType.tags:
        return const GlobalTagsManagerPanel();
      case LeftPanelType.templates:
        return const GlobalTemplatesManagerPanel();
      case LeftPanelType.draw:
        return const GlobalDrawingPanel();
      case LeftPanelType.none:
        return const SizedBox.shrink();
    }
  }
}
