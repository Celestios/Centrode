import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../engine/config.dart';
import '../../store/graph_data_controller.dart';
import '../../presentation/graph_presentation_notifier.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/drawing_interceptor.dart';
import 'active_drawing_painter.dart';
import 'package:mycelium/features/graph/engine/interaction_facade.dart';
import '../../presentation/workspace_tabs_controller.dart';
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import '../../models/models.dart';
import 'layers/grid_layer.dart';
import '../../../../shared/widgets/canvas_interactive_viewer.dart';
import '../widgets/overlays/canvas_tool_ribbon.dart';
import '../widgets/overlays/canvas_tab_bar.dart';
import '../widgets/overlays/left_repository_drawer.dart';
import '../widgets/overlays/right_property_panel.dart';
import '../widgets/overlays/canvas_status_bar/canvas_status_bar.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'context_toolbar_overlay.dart';
import 'package:mycelium/presentation/widgets/tag_manager/global_tags_manager_panel.dart';
import 'package:mycelium/presentation/widgets/template_manager/global_templates_manager_panel.dart';
import 'package:mycelium/presentation/widgets/template_manager/save_template_dialog.dart';
import 'package:mycelium/presentation/widgets/drawing_manager/global_drawing_panel.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with TickerProviderStateMixin {
  ViewportController? _viewportController;
  InteractionController? _interactionController;
  DrawingGestureInterceptor? _drawingInterceptor;
  final Logger _log = Logger('GraphCanvas');
  TabSession? _boundSession;

  GraphPresentationNotifier? _presentationNotifier;

  bool _hasInitialFramed = false;
  bool _viewportRestoreAttempted = false;
  bool _viewportRestored = false;
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier<Offset?>(
    null,
  );
  int _lastMousePosMs = 0;

  void _updateMousePosition(Offset localPosition) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMousePosMs >= 16) {
      // ~60fps
      _lastMousePosMs = now;
      _mousePositionNotifier.value = localPosition;
    }
  }

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
      _boundSession?.toolModeNotifier.addListener(_onToolModeChanged);

      // 2. Build the Environment Facade with separate ViewportController access
      final environment = CanvasInteractionEnvironment(
        dataController: dataController,
        renderState: renderState,
        viewportController: vpController,
        getScale: () =>
            vpController.transformController.value.getMaxScaleOnAxis(),
        boundSession: _boundSession,
        onSaveTemplate: (nodeIds, relationIds) async {
          final name = await showSaveTemplateDialog(context);
          if (name != null) {
            await dataController.saveTemplateFromSelection(
              name,
              nodeIds,
              relationIds,
            );
          }
        },
      );

      // 3. Initialize the pure FSM Engine
      _interactionController = InteractionController(
        transformController: vpController.transformController,
        environment: environment,
      );

      _drawingInterceptor = DrawingGestureInterceptor(
        session: _boundSession!,
        viewportController: vpController,
      );
      _interactionController!.registerInterceptor(_drawingInterceptor!);

      final presentationNotifier = context.read<GraphPresentationNotifier>();
      _presentationNotifier = presentationNotifier;
      _presentationNotifier?.addListener(_onDataControllerChanged);
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
    _presentationNotifier?.removeListener(_onDataControllerChanged);
    _boundSession?.toolModeNotifier.removeListener(_onToolModeChanged);
    if (_boundSession?.viewportController == _viewportController) {
      _boundSession?.viewportController = null;
    }
    _viewportController?.dispose();
    if (_interactionController != null && _drawingInterceptor != null) {
      _interactionController!.unregisterInterceptor(_drawingInterceptor!);
    }
    _drawingInterceptor?.dispose();
    _interactionController?.dispose();
    _mousePositionNotifier.dispose();
    super.dispose();
  }

  void _onToolModeChanged() {
    final mode = _boundSession?.toolModeNotifier.value;
    final renderState = context.read<NodeRenderState>();
    if (mode != 'draw' &&
        renderState.activeLeftPanelNotifier.value == LeftPanelType.draw) {
      renderState.activeLeftPanelNotifier.value = LeftPanelType.none;
    }
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

    final presentationNotifier = context.watch<GraphPresentationNotifier>();

    final backdropRepaintListenable = Listenable.merge([
      viewportController.transformController,
      presentationNotifier,
    ]);

    return MultiProvider(
      providers: [
        Provider<ViewportController>.value(value: viewportController),
        Provider<InteractionController>.value(value: interactionController),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GlassStage(
            mode: GlassMode.performance,
            settings: GlassSettings(
              refractStrength: AppConfig.liquidGlass.refractStrength,
              bridgeReachFactor: AppConfig.liquidGlass.bridgeReachFactor,
              bridgeThicknessFactor:
                  AppConfig.liquidGlass.bridgeThicknessFactor,
              useLocalCoordinates: AppConfig.liquidGlass.useLocalCoordinates,
            ),
            backdropRepaint: backdropRepaintListenable,
            background: DragTarget<Template>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) async {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                final localOffset = renderBox.globalToLocal(details.offset);
                final transform = viewportController.transformController.value;
                if (transform.determinant() == 0.0) return;
                final inverse = Matrix4.inverted(transform);
                final canvasOffset = MatrixUtils.transformPoint(
                  inverse,
                  localOffset,
                );
                await dataController.instantiateTemplate(
                  details.data.key,
                  canvasOffset,
                );
              },
              builder: (context, candidateData, rejectedData) {
                return ValueListenableBuilder<MouseCursor>(
                  valueListenable: interactionController.cursor,
                  builder: (context, cursor, child) {
                    return MouseRegion(
                      cursor: cursor,
                      onExit: (_) {
                        _mousePositionNotifier.value = null;
                        interactionController.environment
                            .setHoveredNodeMetadata(null);
                      },
                      child: child,
                    );
                  },
                  child: Listener(
                    onPointerDown: (event) {
                      interactionController.handlePointerDown(event);
                    },
                    onPointerMove: (event) {
                      interactionController.handlePointerMove(event);
                      _updateMousePosition(event.localPosition);
                    },
                    onPointerUp: (event) {
                      interactionController.handlePointerUp(event);
                    },
                    onPointerCancel: (event) {
                      interactionController.handlePointerCancel(event);
                      _mousePositionNotifier.value = null;
                    },
                    onPointerHover: (event) {
                      interactionController.handlePointerHover(event);
                      _updateMousePosition(event.localPosition);
                    },
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              viewportController.focusOnBounds(
                                dataController.canvasBounds,
                              );
                            });
                          } else {
                            // Still recalc margins after layout
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              viewportController.recalculateElasticMargins();
                            });
                          }
                        }

                        return ValueListenableBuilder<EdgeInsets>(
                          valueListenable: viewportController.elasticMargins,
                          builder: (context, elasticMargins, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable:
                                  interactionController.panScaleEnabled,
                              builder: (context, panScaleEnabled, child) {
                                return ValueListenableBuilder<String>(
                                  valueListenable: session.toolModeNotifier,
                                  builder: (context, currentMode, _) {
                                    // final isDrawMode = currentMode == 'draw';
                                    // final viewerPanEnabled = isDrawMode
                                    //     ? false
                                    //     : panScaleEnabled;
                                    final viewerPanEnabled =
                                        panScaleEnabled &&
                                        renderState.activeEditId == null;
                                    return GestureDetector(
                                      behavior: HitTestBehavior.deferToChild,
                                      onTap: renderState.activeEditId != null
                                          ? null
                                          : () {
                                              renderState.hideFloatingToolbar();
                                            },
                                      onDoubleTap: renderState.activeEditId != null
                                          ? null
                                          : () {},
                                      onLongPress: renderState.activeEditId != null
                                          ? null
                                          : () {},
                                      child: CanvasInteractiveViewer(
                                        transformationController:
                                            viewportController
                                                .transformController,
                                        constrained: true,
                                        clipBehavior: Clip.none,
                                        boundaryMargin: elasticMargins,
                                        minScale: AppConfig.canvas.minScale,
                                        maxScale: AppConfig.canvas.maxScale,
                                        scaleFactor: AppConfig.canvas.scaleFactor,
                                        panEnabled: viewerPanEnabled,
                                        scaleEnabled: viewerPanEnabled,
                                        onInteractionEnd: (details) {
                                          viewportController
                                              .recalculateElasticMargins();
                                        },
                                        child: child!,
                                      ),
                                    );
                                  },
                                );
                              },
                              child: UnboundedStack(
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
                                        mousePositionNotifier:
                                            _mousePositionNotifier,
                                      );
                                    },
                                  ),
                                  const RelationLayer(),
                                  const NodeLayer(),
                                  const OverlayLayer(),
                                  if (_drawingInterceptor != null)
                                    ValueListenableBuilder<List<Offset>>(
                                      valueListenable:
                                          _drawingInterceptor!
                                              .activeStroke,
                                      builder: (context, stroke, _) {
                                        if (stroke.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return IgnorePointer(
                                          child: CustomPaint(
                                            painter: ActiveDrawingPainter(
                                              points: stroke,
                                              brushColor: session
                                                  .brushColorNotifier
                                                  .value,
                                              brushThickness: session
                                                  .brushThicknessNotifier
                                                  .value,
                                              brushType: session
                                                  .brushTypeNotifier
                                                  .value,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            child: Stack(
              children: [
                // Persistent Floating Overlays
                // Top Deck Area (Ribbon, slash separator, and tabs bar on one line)
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
                        Text(
                          '\\',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(child: CanvasTabBar()),
                      ],
                    ),
                  ),
                ),

                // Left repository drawer (floating compact card, width 52)
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

                // Left repository panel
                ValueListenableBuilder<bool>(
                  valueListenable: session.showLeftPanel,
                  builder: (context, leftVisible, _) {
                    return ValueListenableBuilder<LeftPanelType>(
                      valueListenable: renderState.activeLeftPanelNotifier,
                      builder: (context, activeLeftPanel, _) {
                        final isOpen = activeLeftPanel != LeftPanelType.none;
                        // Keep Positioned/AnimatedPositioned clean by evaluating constraints here
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          top: 112.0,
                          left: leftVisible
                              ? 76.0
                              : -300.0, // Clean off-screen translation
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

                // Right property inspector panel
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

                // Bottom control status bar
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

                // Floating Contextual Toolbar Overlay (in screen coordinates)
                if (renderState.selectedEntities.isNotEmpty)
                  ContextToolbarOverlay(
                    renderState: renderState,
                    dataController: dataController,
                    interactionContext: interactionController.environment,
                    viewportController: viewportController,
                    interactionController: interactionController,
                  ),
              ],
            ),
          );
        },
      ),
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

