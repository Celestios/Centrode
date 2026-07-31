import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/logging.dart';
import '../../engine/config.dart';
import '../../store/graph_data_query_controller.dart';
import '../../store/command_queue_processor.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/drawing_interceptor.dart';
import 'painters/active_drawing_painter.dart';
import 'package:centrode/features/graph/engine/interaction_facade.dart';
import '../../presentation/workspace_tabs_controller.dart';
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/port_layer.dart';
import '../../models/models.dart';
import 'layers/grid_layer.dart';
import '../../../../shared/widgets/canvas_interactive_viewer.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/features/graph/ui/widgets/template_manager/save_template_dialog.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import 'canvas_overlay_layout.dart';
import 'canvas_keyboard_handler.dart';
import 'canvas_context_menu.dart';
import 'package:centrode/shared/copy_buffer.dart';

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

  bool _hasInitialFramed = false;
  bool _viewportRestoreAttempted = false;
  bool _viewportRestored = false;
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier<Offset?>(
    null,
  );
  int _lastMousePosMs = 0;
  Offset? _rightClickDownScreenPos;
  bool _isRightClickDrag = false;

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
      _initControllers();
    });
  }

  void _initControllers() {
    final queryController = context.read<GraphDataQueryController>();
    final commandProcessor = context.read<CommandQueueProcessor>();
    final renderState = context.read<NodeRenderState>();

    final vpController = ViewportController(queryController);
    _viewportController = vpController;

    final tabsController = context.read<WorkspaceTabsController>();
    _boundSession = tabsController.activeSession;
    _boundSession?.viewportController = vpController;
    _boundSession?.toolModeNotifier.addListener(_onToolModeChanged);

    final environment = CanvasInteractionEnvironment(
      queryController: queryController,
      commandProcessor: commandProcessor,
      renderState: renderState,
      viewportController: vpController,
      getScale: () =>
          vpController.transformController.value.getMaxScaleOnAxis(),
      boundSession: _boundSession,
      onSaveTemplate: (nodeIds, relationIds) async {
        final name = await showSaveTemplateDialog(context);
        if (name != null) {
          await commandProcessor.templateMutations.saveTemplateFromSelection(
            name,
            nodeIds,
            relationIds,
          );
        }
      },
    );

    _interactionController = InteractionController(
      transformController: vpController.transformController,
      environment: environment,
    );

    _drawingInterceptor = DrawingGestureInterceptor(
      session: _boundSession!,
      viewportController: vpController,
    );
    _interactionController!.registerInterceptor(_drawingInterceptor!);

    _onDataControllerChanged();

    setState(() {});
  }

  void _onDataControllerChanged() {
    if (!mounted) return;
    final queryController = context.read<GraphDataQueryController>();
    if (!queryController.isLoading &&
        !_viewportRestoreAttempted &&
        _viewportController != null) {
      _viewportRestoreAttempted = true;
      final commandProcessor = context.read<CommandQueueProcessor>();
      _viewportRestored = _restoreSavedViewport(commandProcessor);
    }
  }

  bool _restoreSavedViewport(CommandQueueProcessor commandProcessor) {
    final saved = commandProcessor.getSavedViewportState();
    if (saved != null && saved.zoomLevel > 0) {
      final targetMatrix = Matrix4.identity()
        ..translateByDouble(saved.xOffset, saved.yOffset, 0, 1)
        ..scaleByDouble(saved.zoomLevel, saved.zoomLevel, saved.zoomLevel, 1);

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
    CanvasContextMenu.dismiss();
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
    final commandProcessor = context.read<CommandQueueProcessor>();
    final queryController = context.read<GraphDataQueryController>();
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

    final backdropRepaintListenable = Listenable.merge([
      viewportController.transformController,
      renderState.movementNotifier,
    ]);

    return MultiProvider(
      providers: [
        Provider<ViewportController>.value(value: viewportController),
        Provider<InteractionController>.value(value: interactionController),
      ],
      child: CanvasKeyboardHandler(
        viewportController: viewportController,
        mousePositionNotifier: _mousePositionNotifier,
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
                  final transform =
                      viewportController.transformController.value;
                  if (transform.determinant() == 0.0) return;
                  final inverse = Matrix4.inverted(transform);
                  final canvasOffset = MatrixUtils.transformPoint(
                    inverse,
                    localOffset,
                  );
                  await commandProcessor.templateMutations.instantiateTemplate(
                    details.data.key.key.uuid,
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
                        if (event.kind == PointerDeviceKind.mouse &&
                            event.buttons == kSecondaryMouseButton) {
                          _rightClickDownScreenPos = event.position;
                          _isRightClickDrag = false;
                        }
                        interactionController.handlePointerDown(event);
                      },
                      onPointerMove: (event) {
                        if (_rightClickDownScreenPos != null &&
                            !_isRightClickDrag) {
                          final dragDistance =
                              (event.position - _rightClickDownScreenPos!)
                                  .distance;
                          if (dragDistance > 5.0) {
                            _isRightClickDrag = true;
                          }
                        }
                        interactionController.handlePointerMove(event);
                        _updateMousePosition(event.localPosition);
                      },
                      onPointerUp: (event) {
                        if (_rightClickDownScreenPos != null &&
                            !_isRightClickDrag &&
                            renderState.activeEditId == null) {
                          CanvasContextMenu.show(
                            context: context,
                            position: _rightClickDownScreenPos!,
                            queryController: queryController,
                            commandProcessor: commandProcessor,
                            renderState: renderState,
                            copyBuffer: context.read<CopyBuffer>(),
                            viewportController: viewportController,
                          );
                        }
                        _rightClickDownScreenPos = null;
                        _isRightClickDrag = false;
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
                                  queryController.canvasBounds,
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
                                      final viewerPanEnabled =
                                          panScaleEnabled &&
                                          renderState.activeEditId == null;
                                      return GestureDetector(
                                        behavior: HitTestBehavior.deferToChild,
                                        onTap: renderState.activeEditId != null
                                            ? null
                                            : () {
                                                renderState
                                                    .hideFloatingToolbar();
                                              },
                                        onDoubleTap:
                                            renderState.activeEditId != null
                                            ? null
                                            : () {},
                                        onLongPress:
                                            renderState.activeEditId != null
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
                                          scaleFactor:
                                              AppConfig.canvas.scaleFactor,
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
                                    ValueListenableBuilder<ViewportStateGrid>(
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
                                    RelationLayer(),
                                    const NodeLayer(),
                                    const OverlayLayer(),
                                    Positioned.fill(
                                      child: PortLayer(
                                        nodeViewStates: renderState.viewStates,
                                        hoveredNodeNotifier:
                                            renderState.hoveredNodeNotifier,
                                        hoveredPortNotifier:
                                            renderState.hoveredPortNotifier,
                                        interactionState:
                                            interactionController.state,
                                        dragState: renderState.dragState,
                                      ),
                                    ),
                                    if (_drawingInterceptor != null)
                                      ValueListenableBuilder<List<Offset>>(
                                        valueListenable:
                                            _drawingInterceptor!.activeStroke,
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
              child: CanvasOverlayLayout(
                constraints: constraints,
                renderState: renderState,
                queryController: queryController,
                interactionController: interactionController,
                viewportController: viewportController,
                session: session,
                drawingInterceptor: _drawingInterceptor,
              ),
            );
          },
        ),
      ),
    );
  }
}
