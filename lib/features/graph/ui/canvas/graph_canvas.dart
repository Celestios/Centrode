import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../presentation/graph_metrics.dart';
import '../../store/graph_data_controller.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/base_interaction_state.dart';
import 'package:mycelium/features/graph/engine/interaction_facade.dart';
import '../../presentation/workspace_tabs_controller.dart';
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/grid_layer.dart';
import '../../../../shared/widgets/canvas_interactive_viewer.dart';
import '../widgets/overlays/canvas_tool_ribbon.dart';
import '../widgets/overlays/canvas_tab_bar.dart';
import '../widgets/overlays/left_repository_drawer.dart';
import '../widgets/overlays/right_property_panel.dart';
import '../widgets/overlays/canvas_status_bar/canvas_status_bar.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  ViewportController? _viewportController;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas');
  TabSession? _boundSession;

  bool _hasInitialFramed = false;

  @override
  void initState() {
    super.initState();
    _log.info('Initializing GraphCanvas.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dataController = context.read<GraphDataController>();
      final renderState = context.read<NodeRenderState>();

      // 1. Initialize your ViewportController bound directly to the data query layer
      final vpController = ViewportController(dataController);
      _viewportController = vpController;
      
      final tabsController = context.read<WorkspaceTabsController>();
      _boundSession = tabsController.activeSession;
      _boundSession?.viewportController = vpController;

      // 2. Build the Environment Facade with separate ViewportController access
      final environment = CanvasInteractionEnvironment(
        dataController: dataController,
        renderState: renderState,
        viewportController: vpController,
        getScale: () =>
            vpController.transformController.value.getMaxScaleOnAxis(),
        boundSession: _boundSession,
      );

      // 3. Initialize the pure FSM Engine
      _interactionController = InteractionController(
        transformController: vpController.transformController,
        environment: environment,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_boundSession?.viewportController == _viewportController) {
      _boundSession?.viewportController = null;
    }
    _viewportController?.dispose();
    _interactionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderState = context.watch<NodeRenderState>();
    final dataController = context.read<GraphDataController>();
    final interactionController = _interactionController;
    final viewportController = _viewportController;
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;

    // If InteractionController or ViewportController not yet initialized, show loading
    if (!mounted || interactionController == null || viewportController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        Provider<ViewportController>.value(value: viewportController),
        Provider<InteractionController>.value(value: interactionController),
      ],
      child: ValueListenableBuilder<CanvasInteractionState>(
        valueListenable: interactionController.state,
        builder: (context, state, _) {
          return Stack(
            children: [
              // Zoomable / Pannable Interactive Canvas Layer
              Positioned.fill(
                child: MouseRegion(
                  cursor: state.cursor,
                  child: Listener(
                    onPointerDown: interactionController.handlePointerDown,
                    onPointerMove: interactionController.handlePointerMove,
                    onPointerUp: interactionController.handlePointerUp,
                    onPointerCancel: interactionController.handlePointerCancel,
                    onPointerHover: interactionController.handlePointerHover,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = constraints.biggest;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            viewportController.updateViewportSize(viewport);
                          }
                        });

                        if (!_hasInitialFramed && viewport != Size.zero) {
                          _hasInitialFramed = true;
                          _log.info(
                            'CANVAS: Triggering initial camera framing on bounds.',
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            viewportController.focusOnBounds(
                              dataController.canvasBounds.value,
                            );
                          });
                        }

                        return ValueListenableBuilder<EdgeInsets>(
                          valueListenable: viewportController.elasticMargins,
                          builder: (context, elasticMargins, _) {
                            return CanvasInteractiveViewer(
                              transformationController:
                                  viewportController.transformController,
                              constrained: true,
                              boundaryMargin: elasticMargins,
                              minScale: AppConfig.canvas.minScale,
                              maxScale: AppConfig.canvas.maxScale,
                              scaleFactor: AppConfig.canvas.scaleFactor,
                              panEnabled: state is CanvasIdle,
                              scaleEnabled: state is CanvasIdle,
                              onInteractionEnd: (details) {
                                viewportController.recalculateElasticMargins();
                              },
                              child: GestureDetector(
                                onTap: () {
                                  renderState.hideFloatingToolbar();
                                },
                                onDoubleTap: () {},
                                onLongPress: () {},
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ValueListenableBuilder<ViewportStateGrid>(
                                      valueListenable: viewportController
                                          .viewportStateNotifier,
                                      builder: (context, state, _) {
                                        return GridLayer(viewportState: state);
                                      },
                                    ),
                                    RelationLayer(interactionState: state),
                                    const NodeLayer(),
                                    OverlayLayer(interactionState: state),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Persistent Floating Overlays
              // Top Deck Area (Ribbon and tabs below it)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CanvasToolRibbon(),
                    SizedBox(height: 6),
                    CanvasTabBar(),
                  ],
                ),
              ),

              // Left repository drawer
              ValueListenableBuilder<bool>(
                valueListenable: session.showLeftPanel,
                builder: (context, visible, _) {
                  if (!visible) return const SizedBox.shrink();
                  return const Positioned(
                    top: 120,
                    bottom: 86,
                    left: 12,
                    child: LeftRepositoryDrawer(),
                  );
                },
              ),

              // Right property inspector panel
              ValueListenableBuilder<bool>(
                valueListenable: session.showRightPanel,
                builder: (context, visible, _) {
                  if (!visible) return const SizedBox.shrink();
                  return const Positioned(
                    top: 120,
                    bottom: 86,
                    right: 12,
                    child: RightPropertyPanel(),
                  );
                },
              ),

              // Bottom control status bar
              ValueListenableBuilder<bool>(
                valueListenable: session.showBottomPanel,
                builder: (context, visible, _) {
                  if (!visible) return const SizedBox.shrink();
                  return const Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: CanvasStatusBar(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
