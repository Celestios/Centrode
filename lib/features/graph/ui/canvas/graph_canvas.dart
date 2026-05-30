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
import '../../models/models.dart';
import '../../presentation/view_state.dart';
import '../widgets/overlays/vertical_context_toolbar.dart';
import 'layers/grid_layer.dart';
import '../../../../shared/widgets/canvas_interactive_viewer.dart';
import '../widgets/overlays/canvas_tool_ribbon.dart';
import '../widgets/overlays/canvas_tab_bar.dart';
import '../widgets/overlays/left_repository_drawer.dart';
import '../widgets/overlays/right_property_panel.dart';
import '../widgets/overlays/canvas_status_bar/canvas_status_bar.dart';
import '../../../../presentation/widgets/tag_manager/global_tags_manager_panel.dart';
import '../../../../presentation/widgets/template_manager/global_templates_manager_panel.dart';
import '../../../../presentation/widgets/template_manager/save_template_dialog.dart';
import '../../models/left_panel_type.dart';
import '../../../../src/rust/domain/templates.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

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
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier<Offset?>(null);

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
        onSaveTemplate: (nodeIds, relationIds) async {
          final name = await showSaveTemplateDialog(context);
          if (name != null) {
            await dataController.saveTemplateFromSelection(name, nodeIds, relationIds);
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
    if (_boundSession?.viewportController == _viewportController) {
      _boundSession?.viewportController = null;
    }
    _viewportController?.dispose();
    _interactionController?.dispose();
    _mousePositionNotifier.dispose();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Zoomable / Pannable Interactive Canvas Layer
              Positioned.fill(
                child: DragTarget<Template>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) async {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox == null) return;
                    final localOffset = renderBox.globalToLocal(details.offset);
                    final transform = viewportController.transformController.value;
                    if (transform.determinant() == 0.0) return;
                    final inverse = Matrix4.inverted(transform);
                    final canvasOffset = MatrixUtils.transformPoint(inverse, localOffset);
                    await dataController.instantiateTemplate(details.data.key, canvasOffset);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return ValueListenableBuilder<MouseCursor>(
                      valueListenable: interactionController.cursor,
                      builder: (context, cursor, child) {
                        return MouseRegion(
                          cursor: cursor,
                          onExit: (_) {
                            _mousePositionNotifier.value = null;
                          },
                          child: child,
                        );
                      },
                      child: Listener(
                        onPointerDown: interactionController.handlePointerDown,
                        onPointerMove: (event) {
                          interactionController.handlePointerMove(event);
                          _mousePositionNotifier.value = event.localPosition;
                        },
                        onPointerUp: interactionController.handlePointerUp,
                        onPointerCancel: (event) {
                          interactionController.handlePointerCancel(event);
                          _mousePositionNotifier.value = null;
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
                                return ValueListenableBuilder<bool>(
                                  valueListenable:
                                      interactionController.panScaleEnabled,
                                  builder: (context, panScaleEnabled, child) {
                                    return CanvasInteractiveViewer(
                                      transformationController:
                                          viewportController.transformController,
                                      constrained: true,
                                      boundaryMargin: elasticMargins,
                                      minScale: AppConfig.canvas.minScale,
                                      maxScale: AppConfig.canvas.maxScale,
                                      scaleFactor: AppConfig.canvas.scaleFactor,
                                      panEnabled: panScaleEnabled,
                                      scaleEnabled: panScaleEnabled,
                                      onInteractionEnd: (details) {
                                        viewportController
                                            .recalculateElasticMargins();
                                      },
                                      child: child!,
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
                                        ValueListenableBuilder<
                                          ViewportStateGrid
                                        >(
                                          valueListenable: viewportController
                                              .viewportStateNotifier,
                                          builder: (context, state, _) {
                                            return GridLayer(
                                              viewportState: state,
                                              mousePositionNotifier: _mousePositionNotifier,
                                            );
                                          },
                                        ),
                                        const RelationLayer(),
                                        const NodeLayer(),
                                        const OverlayLayer(),
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
              ),

                  // Persistent Floating Overlays
                  // Top Deck Area (Ribbon and tabs below it)
                  Positioned(
                    top: 60.0,
                    left: 0,
                    right: 0,
                    child: RepaintBoundary(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CanvasToolRibbon(),
                          SizedBox(height: 6),
                          CanvasTabBar(),
                        ],
                      ),
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
                          activePanel: _activeLeftPanel,
                          onPanelChanged: (panel) {
                            setState(() {
                              _activeLeftPanel = panel;
                            });
                          },
                        ),
                      );
                    },
                  ),

                  // Left repository panel (opens to the right of the left drawer)
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showLeftPanel,
                    builder: (context, leftVisible, _) {
                      if (!leftVisible) return const SizedBox.shrink();
                      final isOpen = _activeLeftPanel != LeftPanelType.none;
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        top: 178.0,
                        left: 76.0,
                        width: isOpen ? 280.0 : 0.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isOpen ? 1.0 : 0.0,
                          child: ClipRect(
                            child: UnconstrainedBox(
                              alignment: Alignment.topLeft,
                              clipBehavior: Clip.hardEdge,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 280.0,
                                  maxWidth: 280.0,
                                  minHeight: 180,
                                  maxHeight: (constraints.maxHeight - 178 - 86).clamp(180, 10000).toDouble(),
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
                  ValueListenableBuilder<bool>(
                    valueListenable: session.showRightPanel,
                    builder: (context, visible, _) {
                      if (!visible) return const SizedBox.shrink();
                      return Positioned(
                        top: 120,
                        right: 12,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 180,
                            maxHeight: (constraints.maxHeight - 120 - 224).clamp(180, 10000).toDouble(),
                          ),
                          child: const RightPropertyPanel(),
                        ),
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

                  // Floating Contextual Toolbar Overlay (in screen coordinates)
                  if (renderState.selectedEntities.isNotEmpty)
                    _buildContextToolbarOverlay(
                      context,
                      renderState,
                      dataController,
                      viewportController,
                    ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildContextToolbarOverlay(
    BuildContext context,
    NodeRenderState renderState,
    GraphDataController dataController,
    ViewportController viewportController,
  ) {
    final isMulti = renderState.selectedEntities.length > 1;
    final offsetNotifier = isMulti
        ? renderState.multiToolbarOffsetNotifier
        : renderState.toolbarOffsetNotifier;

    // Track offset, transform, and selected entity positions
    final List<Listenable> listenables = [
      offsetNotifier,
      viewportController.transformController,
    ];
    final List<NodeViewState> selectedViewStates = [];
    final List<UiRelation> selectedRelations = [];

    for (final id in renderState.selectedEntities) {
      final vs = renderState.viewStates[id];
      if (vs != null) {
        listenables.add(vs.positionNotifier);
        selectedViewStates.add(vs);
      } else {
        try {
          final rel = dataController.relations.firstWhere((r) => r.id == id);
          selectedRelations.add(rel);
          final sourceVs = renderState.viewStates[rel.fromNodeId];
          final targetVs = renderState.viewStates[rel.toNodeId];
          if (sourceVs != null) listenables.add(sourceVs.positionNotifier);
          if (targetVs != null) listenables.add(targetVs.positionNotifier);
        } catch (_) {}
      }
    }

    final isRelationOnly =
        selectedViewStates.isEmpty && selectedRelations.isNotEmpty;

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        Offset anchor = Offset.zero;
        if (selectedViewStates.isNotEmpty || selectedRelations.isNotEmpty) {
          anchor = renderState.calculateToolbarAnchor(renderState.selectedEntities) ?? Offset.zero;
        }

        final offset = offsetNotifier.value;
        final canvasPosition = anchor + offset;

        // Project canvas coordinate to screen coordinates using viewport matrix
        final matrix = viewportController.transformController.value;
        final screenPosition = MatrixUtils.transformPoint(matrix, canvasPosition);

        final nodeIds = renderState.selectedEntities
            .where((id) => dataController.nodeLookup.containsKey(id))
            .toList();
        final canSaveTemplate = nodeIds.isNotEmpty;
        final String? singleNodeId = (!isMulti && nodeIds.length == 1) ? nodeIds.first : null;

        return Positioned(
          left: screenPosition.dx - 340,
          top: screenPosition.dy,
          child: VerticalContextToolbar(
            onDelete: renderState.deleteSelectedEntities,
            isMulti: isMulti,
            isRelationOnly: isRelationOnly,
            canSaveTemplate: canSaveTemplate,
            singleNodeId: singleNodeId,
            onRelationLayoutChanged: (layoutType) {
              for (final rel in selectedRelations) {
                dataController.updateRelationLayout(
                  rel.id,
                  strategyType: layoutType,
                );
              }
            },
            onDrawConnection: () {
              final nodeIds = renderState.selectedEntities
                  .where((id) => dataController.nodeLookup.containsKey(id))
                  .toList();
              if (nodeIds.isNotEmpty) {
                final vs = renderState.viewStates[nodeIds.first];
                final initialPos = vs != null ? vs.rect.center : Offset.zero;
                _interactionController?.state.value = RelationDrawing(
                  nodeIds.toSet(),
                  initialPos,
                  isSticky: true,
                  hasReleasedOnce: true,
                );
              }
            },
            onDecreaseFontSize: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize - 2.0).clamp(8.0, 24.0),
                  );
                });
              }
            },
            onIncreaseFontSize: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize + 2.0).clamp(8.0, 24.0),
                  );
                });
              }
            },
            onToggleFontFamily: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  final nextFont = style.fontFamily == 'Roboto' ? 'Inter' : 'Roboto';
                  return style.copyWith(fontFamily: nextFont);
                });
              }
            },
            onCycleTextColor: () {
              if (singleNodeId != null) {
                const textColors = [
                  0xFF000000, // Black
                  0xFFFFFFFF, // White
                  0xFF0D47A1, // Dark Blue
                  0xFF1B5E20, // Dark Green
                  0xFF880E4F, // Dark Pink/Rose
                  0xFFE65100, // Dark Orange
                  0xFF263238, // Charcoal
                ];
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  final index = textColors.indexOf(style.textColor);
                  final nextColor = textColors[(index + 1) % textColors.length];
                  return style.copyWith(textColor: nextColor);
                });
              }
            },
            onShapeChanged: (shape) {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(shape: shape);
                });
              }
            },
            onSaveTemplate: () async {
              final nodeIds = renderState.selectedEntities
                  .where((id) => dataController.nodeLookup.containsKey(id))
                  .toList();
              final relationIds = renderState.selectedEntities
                  .where((id) => dataController.relationLookup.containsKey(id))
                  .toList();
              final name = await showSaveTemplateDialog(context);
              if (name != null) {
                await dataController.saveTemplateFromSelection(name, nodeIds, relationIds);
              }
            },
            dragHandle: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final scale = matrix.getMaxScaleOnAxis();
                  if (scale > 0) {
                    offsetNotifier.value += details.delta / scale;
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanelContent() {
    switch (_activeLeftPanel) {
      case LeftPanelType.tags:
        return const GlobalTagsManagerPanel();
      case LeftPanelType.templates:
        return const GlobalTemplatesManagerPanel();
      case LeftPanelType.none:
        return const SizedBox.shrink();
    }
  }

  NodeStyle _getEffectiveStyle(UiNode node) {
    return node.style ?? NodeStyleStrategy.resolveStyle(node);
  }

  void _updateNodeStyle(
    String nodeId,
    GraphDataController dataController,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    final node = dataController.nodeLookup[nodeId];
    if (node != null) {
      final style = _getEffectiveStyle(node);
      dataController.updateNodeStyle(nodeId, updateFn(style));
    }
  }
}
