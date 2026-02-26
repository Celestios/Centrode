import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/app_config.dart';
import '../../state/graph_data_controller.dart';
import '../../state/graph_ui_controller.dart';
import '../../state/viewport_controller.dart';
import '../../state/interaction_controller.dart';
import '../../state/canvas_interaction_states.dart';
import '../../domain/models.dart';
import '../../domain/styling.dart';
import '../../../../src/rust/domain/base_models.dart' show BoundingBox;
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/grid_layer.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late final ViewportController _viewportController;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas');

  // NEW: State flag to ensure we only frame the camera once on load
  bool _hasInitialFramed = false;

  @override
  void initState() {
    super.initState();
    _log.info('Initializing GraphCanvas.');

    // Initialize InteractionController after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataController = context.read<GraphDataController>();
      final uiController = context.read<GraphUIController>();

      _viewportController = ViewportController(uiController);

      _interactionController = InteractionController(
        transformController: _viewportController.transformController,
        nodeViewStates: dataController.allNodeViewStates,
        onNodeMove: dataController.updateNodePosition,
        onRelationCreate: dataController.createRelation,
        onNodeDragUpdate: dataController.movementNotifier.pulse,
        // Route volatile interactions to UIController
        getActiveEditId: () => uiController.activeEditId,
        onEnterEditMode: uiController.enterEditMode,
        onCommitActiveEdit: uiController.cancelActiveEdit,
        // Route data operations to DataController
        getRelations: () => dataController.relations.toList(),
        // [REFACTORED]: Synchronous execution restores T=0 Optimistic UI
        onCreateNode: (pos) {
          final tempId = dataController.createNode(
            UiNodeType.info,
            pos,
            onIdSwap: uiController.handleIdSwap, // Delegate ID swap updates
          );

          // Only force visibility if the set is already active.
          // If empty, the bypass in NodeLayer handles it safely.
          if (uiController.visibleNodeIds.value.isNotEmpty) {
            uiController.visibleNodeIds.value = {
              ...uiController.visibleNodeIds.value,
              tempId,
            };

            // THE FIX: Symmetrical Physics State.
            // We MUST also push this into the Z-Order stack so the FSM can hit-test it
            // before the next pan/zoom viewport recalculation occurs.
            if (!uiController.zOrder.contains(tempId)) {
              uiController.zOrder.add(tempId);
            }
          }
          uiController.enterEditMode(tempId);
        },
        onNodeResizeEnd: (id, newWidth) => dataController.updateNodeAesthetics(
          id,
          StyleProfile(width: newWidth),
        ),
        // Selection state from UIController
        onSelectEntity: uiController.selectEntity,
        onSelectEntities: uiController.selectEntities,
        getSelectedEntities: () => uiController.selectedEntities,
        getToolbarOffset: () => uiController.selectedEntities.length > 1
            ? uiController.multiToolbarOffsetNotifier.value
            : uiController.toolbarOffsetNotifier.value,
        updateToolbarOffset: (delta) {
          if (uiController.selectedEntities.length > 1) {
            uiController.multiToolbarOffsetNotifier.value = delta;
          } else {
            uiController.toolbarOffsetNotifier.value = delta;
          }
        },
        onDeleteSelectedEntities: uiController.deleteSelectedEntities,
        getVisibleNodeIds: () => uiController.visibleNodeIds.value,
        getZOrder: () => uiController.zOrder,
      );
      // Trigger rebuild to use the initialized controller
      setState(() {});
    });
  }

  @override
  void dispose() {
    _viewportController.dispose();
    _interactionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiController = context.watch<GraphUIController>();
    final dataController = context.read<GraphDataController>();
    final interactionController = _interactionController;

    // If InteractionController not yet initialized, show loading
    if (!mounted || interactionController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<CanvasInteractionState>(
      valueListenable: interactionController.state,
      builder: (context, state, _) {
        return Stack(
          children: [
            MouseRegion(
              cursor: state.cursor,
              child: Listener(
                onPointerDown: interactionController.handlePointerDown,
                onPointerMove: interactionController.handlePointerMove,
                onPointerUp: interactionController.handlePointerUp,
                onPointerCancel: interactionController.handlePointerCancel,
                onPointerHover: interactionController.handlePointerHover,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Guarded update: Feed dimensions to purely mathematical controller
                    _viewportController.updateViewportSize(constraints.biggest);

                    final viewport = constraints.biggest;

                    // NEW: Trigger initial camera framing once we have physical dimensions
                    if (!_hasInitialFramed && viewport != Size.zero) {
                      _hasInitialFramed = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _viewportController.focusOnBounds(
                          dataController.canvasBounds.value,
                        );
                      });
                    }

                    // NEW: Listen to the elastic boundaries from the Rust core
                    return ValueListenableBuilder<BoundingBox>(
                      valueListenable: dataController.canvasBounds,
                      builder: (context, bounds, _) {
                        // Calculate dynamic padding to provide the "Elastic Buffer"
                        final padding =
                            AppConfig.graph.canvas.boundaryMargin; // 500.0

                        // THE FIX: Scale-Aware Geometric Decoupling.
                        // The margin must NEVER be smaller than the maximum possible zoomed-out screen.
                        final minScale = AppConfig.graph.canvas.minScale;
                        final effectiveViewportWidth =
                            viewport.width / minScale;
                        final effectiveViewportHeight =
                            viewport.height / minScale;

                        final leftBound = math.max(
                          effectiveViewportWidth,
                          -bounds.minX.toDouble() + padding,
                        );
                        final topBound = math.max(
                          effectiveViewportHeight,
                          -bounds.minY.toDouble() + padding,
                        );
                        final rightBound = math.max(
                          effectiveViewportWidth,
                          bounds.maxX.toDouble() + padding,
                        );
                        final bottomBound = math.max(
                          effectiveViewportHeight,
                          bounds.maxY.toDouble() + padding,
                        );

                        final elasticMargins = EdgeInsets.fromLTRB(
                          leftBound,
                          topBound,
                          rightBound,
                          bottomBound,
                        );

                        return InteractiveViewer(
                          transformationController:
                              _viewportController.transformController,
                          constrained: false,
                          boundaryMargin:
                              elasticMargins, // <-- Apply Elastic Math
                          minScale: AppConfig.graph.canvas.minScale,
                          maxScale: AppConfig.graph.canvas.maxScale,
                          // Lock viewer if interaction is active (arena circumvention)
                          panEnabled: state is CanvasIdle,
                          scaleEnabled: state is CanvasIdle,
                          child: GestureDetector(
                            // Tap empty space to dismiss menus
                            onTap: () {
                              uiController.hideDeleteMenu();
                            },
                            // 1x1 Mathematical Reference Plane
                            // (Satisfies Pitfall #5 layout requirements without inflating pan area)
                            child: SizedBox(
                              width: 1,
                              height: 1,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GridLayer(
                                    transformController:
                                        _viewportController.transformController,
                                    viewportSize: constraints.biggest,
                                  ),
                                  const RelationLayer(),
                                  const NodeLayer(),
                                  OverlayLayer(
                                    interactionState: state,
                                    nodeViewStates:
                                        interactionController.nodeViewStates,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
