import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/infrastructure/telemetry/logging.dart';
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
import 'layers/port_layer.dart';
import '../../models/models.dart';
import 'layers/grid_layer.dart';
import '../../../../shared/widgets/canvas_interactive_viewer.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'package:mycelium/presentation/widgets/template_manager/save_template_dialog.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';
import 'canvas_overlay_layout.dart';
import 'paste_handler.dart';
import 'package:mycelium/features/workspace/copy_buffer.dart';
import '../../../../shared/widgets/context_menu_overlay.dart';

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
  Offset? _rightClickDownScreenPos;
  bool _isRightClickDrag = false;
  OverlayEntry? _canvasContextMenuEntry;

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
    final dataController = context.read<GraphDataController>();
    final renderState = context.read<NodeRenderState>();

    final vpController = ViewportController(dataController);
    _viewportController = vpController;

    final tabsController = context.read<WorkspaceTabsController>();
    _boundSession = tabsController.activeSession;
    _boundSession?.viewportController = vpController;
    _boundSession?.toolModeNotifier.addListener(_onToolModeChanged);

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
  }

  void _onDataControllerChanged() {
    if (!mounted) return;
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

  void _dismissCanvasContextMenu() {
    try {
      _canvasContextMenuEntry?.remove();
    } catch (_) {}
    _canvasContextMenuEntry = null;
  }

  void _showCanvasContextMenu(Offset screenPosition) {
    _dismissCanvasContextMenu();

    final dataController = context.read<GraphDataController>();
    final renderState = context.read<NodeRenderState>();
    final copyBuffer = context.read<CopyBuffer>();
    final viewportController = _viewportController;
    if (viewportController == null) return;

    _canvasContextMenuEntry = ContextMenuOverlay.show(
      context: context,
      position: screenPosition,
      items: [
        ContextMenuItem(
          label: 'Copy',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, dataController);
            }
          },
        ),
        ContextMenuItem(
          label: 'Cut',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, dataController);
              renderState.deleteSelectedEntities();
            }
          },
        ),
        ContextMenuItem(
          label: 'Paste',
          onTap: () async {
            if (copyBuffer.hasData) {
              final transform =
                  viewportController.transformController.value;
              final canvasPos = transform.determinant() == 0.0
                  ? Offset.zero
                  : MatrixUtils.transformPoint(
                      Matrix4.inverted(transform),
                      screenPosition,
                    );
              final newIds = await copyBuffer.paste(canvasPos, dataController);
              if (newIds.isNotEmpty) {
                renderState.selectEntities(newIds);
              }
            } else {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null && data!.text!.isNotEmpty) {
                final transform =
                    viewportController.transformController.value;
                final canvasPos = transform.determinant() == 0.0
                    ? Offset.zero
                    : MatrixUtils.transformPoint(
                        Matrix4.inverted(transform),
                        screenPosition,
                      );
                await pasteTextToCanvas(
                  dataController: dataController,
                  text: data.text!,
                  canvasPosition: canvasPos,
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dismissCanvasContextMenu();
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

  void _handleCanvasCopy(
    GraphDataController dataController,
    NodeRenderState renderState,
  ) {
    final selectedIds = renderState.selectedEntities.toList();
    if (selectedIds.isEmpty) return;

    final copyBuffer = context.read<CopyBuffer>();
    copyBuffer.copy(selectedIds, dataController);
  }

  void _handleCanvasCut(
    GraphDataController dataController,
    NodeRenderState renderState,
  ) {
    final selectedIds = renderState.selectedEntities.toList();
    if (selectedIds.isEmpty) return;

    final copyBuffer = context.read<CopyBuffer>();
    copyBuffer.copy(selectedIds, dataController);
    renderState.deleteSelectedEntities();
  }

  Future<void> _handleCanvasPaste(
    GraphDataController dataController,
    NodeRenderState renderState,
  ) async {
    if (renderState.activeEditId != null) return;

    final mousePos = _mousePositionNotifier.value;
    if (mousePos == null) return;

    final viewportController = _viewportController;
    if (viewportController == null) return;

    final transform = viewportController.transformController.value;
    if (transform.determinant() == 0.0) return;

    final canvasPos = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      mousePos,
    );

    final copyBuffer = context.read<CopyBuffer>();
    if (copyBuffer.hasData) {
      final newIds = await copyBuffer.paste(canvasPos, dataController);
      if (newIds.isNotEmpty) {
        renderState.selectEntities(newIds);
      }
      return;
    }

    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      await pasteTextToCanvas(
        dataController: dataController,
        text: data.text!,
        canvasPosition: canvasPos,
      );
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
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyC &&
                HardwareKeyboard.instance.isControlPressed) {
              _handleCanvasCopy(dataController, renderState);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyX &&
                HardwareKeyboard.instance.isControlPressed) {
              _handleCanvasCut(dataController, renderState);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyV &&
                HardwareKeyboard.instance.isControlPressed) {
              _handleCanvasPaste(dataController, renderState);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
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
                      if (event.kind == PointerDeviceKind.mouse &&
                          event.buttons == kSecondaryMouseButton) {
                        _rightClickDownScreenPos = event.position;
                        _isRightClickDrag = false;
                      }
                      interactionController.handlePointerDown(event);
                    },
                    onPointerMove: (event) {
                      if (_rightClickDownScreenPos != null && !_isRightClickDrag) {
                        final dragDistance =
                            (event.position - _rightClickDownScreenPos!).distance;
                        if (dragDistance > 5.0) {
                          _isRightClickDrag = true;
                        }
                      }
                      interactionController.handlePointerMove(event);
                      _updateMousePosition(event.localPosition);
                    },
                    onPointerUp: (event) {
                      if (_rightClickDownScreenPos != null && !_isRightClickDrag && renderState.activeEditId == null) {
                        _showCanvasContextMenu(_rightClickDownScreenPos!);
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
                                  Positioned.fill(
                                    child: PortLayer(
                                      nodeViewStates: renderState.viewStates,
                                      hoveredNodeNotifier: renderState.hoveredNodeNotifier,
                                      interactionState: interactionController.state,
                                      dragState: renderState.dragState,
                                    ),
                                  ),
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
            child: CanvasOverlayLayout(
              constraints: constraints,
              renderState: renderState,
              dataController: dataController,
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

