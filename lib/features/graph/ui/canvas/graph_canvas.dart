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
import '../../../../presentation/widgets/tag_manager/global_tags_manager_panel.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with TickerProviderStateMixin {
  ViewportController? _viewportController;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas');
  TabSession? _boundSession;

  GraphDataController? _dataController;

  bool _hasInitialFramed = false;
  bool _viewportRestoreAttempted = false;
  bool _viewportRestored = false;
  bool _isTagManagerOpen = false;

  @override
  void initState() {
    super.initState();
    _log.info('Initializing GraphCanvas.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dataController = context.read<GraphDataController>();
      _dataController = dataController;
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

      dataController.addListener(_onDataControllerChanged);
      _onDataControllerChanged();

      setState(() {});
    });
  }

  void _onDataControllerChanged() {
    final dataController = context.read<GraphDataController>();
    if (!dataController.isLoading &&
        !_viewportRestoreAttempted &&
        _viewportController != null) {
      _viewportRestoreAttempted = true;
      _viewportRestored = _restoreSavedViewport(dataController);
    }
  }

  bool _restoreSavedViewport(GraphDataController dataController) {
    final saved = dataController.getSavedViewportState();
    if (saved != null && saved.zoomLevel > 0) {
      final targetMatrix = Matrix4.identity()
        ..translate(saved.xOffset, saved.yOffset)
        ..scale(saved.zoomLevel);

      _viewportController?.animateViewportTo(targetMatrix, this);
      _log.info(
        'Restored viewport: offset(${saved.xOffset}, ${saved.yOffset}), zoom ${saved.zoomLevel}',
      );
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _dataController?.removeListener(_onDataControllerChanged);
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
    if (!mounted ||
        interactionController == null ||
        viewportController == null) {
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
          return LayoutBuilder(
            builder: (context, constraints) {
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
                        onPointerCancel:
                            interactionController.handlePointerCancel,
                        onPointerHover:
                            interactionController.handlePointerHover,
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
                              // Only auto-frame if no saved state was restored
                              if (!_viewportRestored) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  viewportController.focusOnBounds(
                                    dataController.canvasBounds.value,
                                  );
                                });
                              } else {
                                // Still recalc margins after layout
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  viewportController
                                      .recalculateElasticMargins();
                                });
                              }
                            }

                            return ValueListenableBuilder<EdgeInsets>(
                              valueListenable:
                                  viewportController.elasticMargins,
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
                                    viewportController
                                        .recalculateElasticMargins();
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
                                        ValueListenableBuilder<
                                          ViewportStateGrid
                                        >(
                                          valueListenable: viewportController
                                              .viewportStateNotifier,
                                          builder: (context, state, _) {
                                            return GridLayer(
                                              viewportState: state,
                                            );
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

                  // Left repository drawer (floating compact card, width 52)
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showLeftPanel,
                    builder: (context, leftVisible, _) {
                      if (!leftVisible) return const SizedBox.shrink();
                      return Positioned(
                        top: 178.0,
                        left: 12,
                        width: 52,
                        child: LeftRepositoryDrawer(
                          isTagManagerOpen: _isTagManagerOpen,
                          onTapTags: () {
                            setState(() {
                              _isTagManagerOpen = !_isTagManagerOpen;
                            });
                          },
                        ),
                      );
                    },
                  ),

                  // Global Tags Manager Panel (opens to the right of the left drawer)
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showLeftPanel,
                    builder: (context, leftVisible, _) {
                      if (!leftVisible) return const SizedBox.shrink();
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        top: 178.0,
                        left: 76.0,
                        bottom: 86.0,
                        width: _isTagManagerOpen ? 280.0 : 0.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isTagManagerOpen ? 1.0 : 0.0,
                          child: const ClipRect(
                            child: OverflowBox(
                              minWidth: 280.0,
                              maxWidth: 280.0,
                              alignment: Alignment.topLeft,
                              child: GlobalTagsManagerPanel(),
                            ),
                          ),
                        ),
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
          );
        },
      ),
    );
  }
}
