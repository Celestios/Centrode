import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../presentation/graph_metrics.dart';
import '../../store/graph_data_controller.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
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
import '../../../../presentation/widgets/tag_manager/global_tags_manager_panel.dart';
import '../../../../presentation/widgets/template_manager/global_templates_manager_panel.dart';
import '../../../../presentation/widgets/drawing_manager/global_drawing_panel.dart';
import '../../../../presentation/widgets/template_manager/save_template_dialog.dart';
import '../../models/left_panel_type.dart';

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
  LeftPanelType _activeLeftPanel = LeftPanelType.none;
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier<Offset?>(
    null,
  );

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
    _boundSession?.toolModeNotifier.removeListener(_onToolModeChanged);
    if (_boundSession?.viewportController == _viewportController) {
      _boundSession?.viewportController = null;
    }
    _viewportController?.dispose();
    _interactionController?.dispose();
    _mousePositionNotifier.dispose();
    super.dispose();
  }

  void _onToolModeChanged() {
    final mode = _boundSession?.toolModeNotifier.value;
    if (mode != 'draw' && _activeLeftPanel == LeftPanelType.draw) {
      setState(() {
        _activeLeftPanel = LeftPanelType.none;
      });
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

    final backdropRepaintListenable = Listenable.merge([
      viewportController.transformController,
      dataController,
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
            settings: AppConfig.liquidGlass.settings,
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
                        interactionController.environment.setHoveredNodeMetadata(null);
                      },
                      child: child,
                    );
                  },
                  child: Listener(
                    onPointerDown: (event) {
                      if (session.toolModeNotifier.value == 'draw') {
                        _startDrawing(event, viewportController);
                      } else {
                        interactionController.handlePointerDown(event);
                      }
                    },
                    onPointerMove: (event) {
                      if (session.toolModeNotifier.value == 'draw') {
                        _updateDrawing(event, viewportController);
                      } else {
                        interactionController.handlePointerMove(event);
                        _mousePositionNotifier.value = event.localPosition;
                      }
                    },
                    onPointerUp: (event) {
                      if (session.toolModeNotifier.value == 'draw') {
                        _endDrawing(dataController, session);
                      } else {
                        interactionController.handlePointerUp(event);
                      }
                    },
                    onPointerCancel: (event) {
                      if (session.toolModeNotifier.value == 'draw') {
                        _cancelDrawing();
                      } else {
                        interactionController.handlePointerCancel(event);
                        _mousePositionNotifier.value = null;
                      }
                    },
                    onPointerHover: (event) {
                      interactionController.handlePointerHover(event);
                      _mousePositionNotifier.value = event.localPosition;
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
                                dataController.canvasBounds.value,
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
                                    final isDrawMode = currentMode == 'draw';
                                    final viewerPanEnabled = isDrawMode ? false : panScaleEnabled;
                                    return CanvasInteractiveViewer(
                                      transformationController:
                                          viewportController.transformController,
                                      constrained: true,
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
                                    );
                                  },
                                );
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
                                    if (_activeStroke.isNotEmpty)
                                      IgnorePointer(
                                        child: CustomPaint(
                                          painter: ActiveDrawingPainter(
                                            points: _activeStroke,
                                            brushColor: session.brushColorNotifier.value,
                                            brushThickness: session.brushThicknessNotifier.value,
                                            brushType: session.brushTypeNotifier.value,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: CanvasTabBar(),
                        ),
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
                      return LeftRepositoryDrawer(
                        activePanel: _activeLeftPanel,
                        onPanelChanged: (panel) {
                          setState(() {
                            _activeLeftPanel = panel;
                            if (panel == LeftPanelType.draw) {
                              session.toolModeNotifier.value = 'draw';
                            } else {
                              session.toolModeNotifier.value = 'select';
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

                // Left repository panel
                ValueListenableBuilder<bool>(
                  valueListenable: session.showLeftPanel,
                  builder: (context, leftVisible, _) {
                    final isOpen = _activeLeftPanel != LeftPanelType.none;
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
                                maxHeight: (constraints.maxHeight - 112 - 86)
                                    .clamp(180, 10000)
                                    .toDouble(),
                              ),
                              child: _buildLeftPanelContent(),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildLeftPanelContent() {
    switch (_activeLeftPanel) {
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

  List<Offset> _activeStroke = [];

  Offset _getLocalCanvasCoords(Offset localPosition, ViewportController viewportController) {
    final transform = viewportController.transformController.value;
    if (transform.determinant() == 0.0) return localPosition;
    final inverse = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(inverse, localPosition);
  }

  void _startDrawing(PointerDownEvent event, ViewportController viewportController) {
    setState(() {
      _activeStroke = [_getLocalCanvasCoords(event.localPosition, viewportController)];
    });
  }

  void _updateDrawing(PointerMoveEvent event, ViewportController viewportController) {
    final currentPoint = _getLocalCanvasCoords(event.localPosition, viewportController);
    final type = _boundSession?.brushTypeNotifier.value ?? 'pen';
    setState(() {
      if (type == 'line') {
        if (_activeStroke.isNotEmpty) {
          _activeStroke = [_activeStroke.first, currentPoint];
        } else {
          _activeStroke = [currentPoint];
        }
      } else {
        _activeStroke.add(currentPoint);
      }
    });
  }

  void _endDrawing(GraphDataController dataController, TabSession session) {
    if (_activeStroke.length < 2) {
      _cancelDrawing();
      return;
    }

    double minX = _activeStroke.first.dx;
    double maxX = _activeStroke.first.dx;
    double minY = _activeStroke.first.dy;
    double maxY = _activeStroke.first.dy;

    for (final p in _activeStroke) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    if (width < 2 && height < 2) {
      _cancelDrawing();
      return;
    }

    const padding = 12.0;
    final normalizedPoints = _activeStroke.map((p) {
      final rx = p.dx - minX + padding;
      final ry = p.dy - minY + padding;
      return '${rx.toStringAsFixed(1)},${ry.toStringAsFixed(1)}';
    }).join(';');

    final nodePosition = Offset(minX - padding, minY - padding);
    final nodeSize = Size(width + padding * 2, height + padding * 2);

    final brushColor = session.brushColorNotifier.value;
    final brushThickness = session.brushThicknessNotifier.value;
    final brushType = session.brushTypeNotifier.value;

    dataController.createNode(
      UiNodes.drawing,
      nodePosition,
      paths: [normalizedPoints],
      brushType: brushType,
      brushThickness: brushThickness,
      brushColor: brushColor,
      size: nodeSize,
    );

    _cancelDrawing();
  }

  void _cancelDrawing() {
    setState(() {
      _activeStroke = [];
    });
  }
}

class ActiveDrawingPainter extends CustomPainter {
  final List<Offset> points;
  final String brushColor;
  final double brushThickness;
  final String brushType;

  ActiveDrawingPainter({
    required this.points,
    required this.brushColor,
    required this.brushThickness,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    Color color;
    try {
      final hex = brushColor.replaceFirst('#', '').replaceFirst('0x', '');
      if (hex.length == 6) {
        color = Color(int.parse('FF$hex', radix: 16));
      } else {
        color = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      color = const Color(0xFF00E5FF);
    }

    if (brushType == 'highlighter') {
      color = color.withValues(alpha: 0.4);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ActiveDrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.brushThickness != brushThickness ||
        oldDelegate.brushType != brushType;
  }
}

