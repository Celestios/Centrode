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
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late final ViewportController _viewportController;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas');

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

          // Force visibility for the new node to prevent culling before a pan/zoom occurs
          uiController.visibleNodeIds.value = {
            ...uiController.visibleNodeIds.value,
            tempId,
          };
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
        getToolbarOffset: () => uiController.toolbarOffsetNotifier.value,
        updateToolbarOffset: (delta) =>
            uiController.toolbarOffsetNotifier.value = delta,
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
            Listener(
              onPointerDown: interactionController.handlePointerDown,
              onPointerMove: interactionController.handlePointerMove,
              onPointerUp: interactionController.handlePointerUp,
              onPointerCancel: interactionController.handlePointerCancel,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Guarded update: Feed dimensions to purely mathematical controller
                  _viewportController.updateViewportSize(constraints.biggest);

                  return InteractiveViewer(
                    transformationController:
                        _viewportController.transformController,
                    constrained: false,
                    boundaryMargin: EdgeInsets.all(
                      AppConfig.graph.canvas.boundaryMargin,
                    ),
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
                      child: SizedBox(
                        width: AppConfig.graph.canvas.initialSize,
                        height: AppConfig.graph.canvas.initialSize,
                        child: Stack(
                          children: [
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
              ),
            ),
          ],
        );
      },
    );
  }
}
