import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/app_config.dart';
import '../../state/graph_data_controller.dart';
import '../../state/graph_ui_controller.dart';
import '../../state/interaction_controller.dart';
import '../../state/canvas_interaction_states.dart';
import '../../state/viewport_controller.dart';
import '../../domain/models.dart';
import '../../domain/styling.dart';
import 'node_widget.dart';
import 'relation_painter.dart';
import 'inline_editor_overlay.dart';

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
    final dataController = context.watch<GraphDataController>();
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
                            // 0. The Relations Layer (Bottom) - Isolated with RepaintBoundary
                            // Uses allNodeViewStates to resolve positions for culled nodes
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: ListenableBuilder(
                                  listenable: dataController.movementNotifier,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: RelationPainter(
                                        dataController.relations.toList(),
                                        dataController.allNodeViewStates,
                                        uiController.selectedEntities,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 1. The Nodes Layer - Only renders visible nodes via ValueListenableBuilder
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: uiController.visibleNodeIds,
                              builder: (context, visibleIds, _) {
                                // If no visible set calculated yet, render all nodes
                                final nodeIds = visibleIds.isEmpty
                                    ? dataController.nodes
                                          .map((n) => n.id)
                                          .toList()
                                    : visibleIds.toList();

                                // Update z-order in InteractionController
                                interactionController.updateZOrder(nodeIds);

                                // [FIX]: Defensive Data Projection - Filter orphaned IDs before Widget inflation
                                final validNodeIds = nodeIds.where(
                                  (id) =>
                                      dataController.allNodeViewStates
                                          .containsKey(id) &&
                                      dataController.nodeLookup.containsKey(id),
                                );

                                return Stack(
                                  children: validNodeIds.map((id) {
                                    // Safe to force-unwrap because of the strict pre-filter above
                                    final viewState =
                                        dataController.allNodeViewStates[id]!;
                                    final node = dataController.nodeLookup[id]!;

                                    return Positioned(
                                      key: ValueKey(id),
                                      left: 0,
                                      top:
                                          0, // Positioned via Transform in NodeWidget
                                      child: NodeWidget(
                                        viewState: viewState,
                                        node: node,
                                        isDeleteMenuVisible:
                                            uiController
                                                .nodeShowingDeleteMenu ==
                                            node.id,
                                        onDelete: () =>
                                            dataController.deleteNode(node.id),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            // 2. Absolute Zenith: Transient Editor Overlay
                            // Unified overlay for both nodes and relations
                            if (uiController.activeEditId != null)
                              InlineEditorOverlay(
                                key: ValueKey(
                                  'editor_${uiController.activeEditId}',
                                ),
                                entityId: uiController.activeEditId!,
                                initialText:
                                    dataController
                                        .nodeLookup[uiController.activeEditId!]
                                        ?.text ??
                                    dataController.relations
                                        .firstWhere(
                                          (r) =>
                                              r.id ==
                                              uiController.activeEditId!,
                                        )
                                        .label,
                              ),

                            // 3. Temporary Relation Drag Line (when drawing relation)
                            if (state is RelationDrawing)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _TempRelationPainter(
                                    state: state,
                                    nodeViewStates:
                                        interactionController.nodeViewStates,
                                  ),
                                ),
                              ),

                            // 4. Marquee Selection Box Layer
                            if (state is MarqueeSelecting)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _MarqueePainter(state: state),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2.5: THE UNIFIED FLOATING TOOLBAR
            if (uiController.selectedEntities.isNotEmpty)
              _buildUnifiedToolbar(context, uiController, dataController),
          ],
        );
      },
    );
  }

  /// Unified toolbar orchestrator that adapts based on selection count.
  /// For single selection, anchors to node position; for multi, anchors to screen center.
  Widget _buildUnifiedToolbar(
    BuildContext context,
    GraphUIController ui,
    GraphDataController data,
  ) {
    final isMulti = ui.selectedEntities.length > 1;
    final notifier = isMulti
        ? ui.multiToolbarOffsetNotifier
        : ui.toolbarOffsetNotifier;

    return ValueListenableBuilder<Offset>(
      valueListenable: notifier,
      builder: (context, offset, _) {
        // For single, anchor to node; for multi, anchor to screen center
        final position = isMulti
            ? Offset(
                (MediaQuery.of(context).size.width / 2) -
                    (AppConfig.graph.toolbar.multiWidth / 2) +
                    offset.dx,
                offset.dy,
              )
            : (data
                          .allNodeViewStates[ui.selectedEntities.first]
                          ?.positionNotifier
                          .value ??
                      Offset.zero) +
                  offset;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: isMulti ? (d) => notifier.value += d.delta : null,
            child: _buildToolbarUI(
              onDelete: ui.deleteSelectedEntities,
              isMulti: isMulti,
            ),
          ),
        );
      },
    );
  }

  // Helper method to build toolbar UI
  // Three zones: Drag (left), Link (center), Delete (right)
  Widget _buildToolbarUI({
    required VoidCallback onDelete,
    required bool isMulti,
  }) {
    final width = isMulti
        ? AppConfig.graph.toolbar.multiWidth
        : AppConfig.graph.toolbar.singleWidth;
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: AppConfig.graph.toolbar.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blueAccent.withValues(alpha: isMulti ? 0.8 : 0.3),
          ),
        ),
        child: Row(
          children: [
            // Zone 1: Drag Handle
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Container(width: 1, color: Colors.grey.shade300),
            // Zone 2: Link Button
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Listener(
                  onPointerDown: (e) {
                    // Trigger Sticky RelationDrawing - this will be handled by the InteractionController
                    // The toolbar hit-testing in CanvasIdle will detect this and transition to RelationDrawing
                  },
                  child: Icon(
                    Icons.link,
                    size: 20,
                    color: Colors.blueAccent.shade700,
                  ),
                ),
              ),
            ),
            Container(width: 1, color: Colors.grey.shade300),
            // Zone 3: Delete Button
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter for the temporary relation line during drag.
/// Supports multiple source nodes (multi-selection) drawing lines to a single
/// target or cursor position.
class _TempRelationPainter extends CustomPainter {
  final RelationDrawing state;
  final Map<String, NodeViewState> nodeViewStates;

  _TempRelationPainter({required this.state, required this.nodeViewStates});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = state.snappedTargetNodeId != null
          ? Colors.green
          : Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // End position - either snapped target's left port or cursor position
    Offset endPos;
    if (state.snappedTargetNodeId != null) {
      final targetVs = nodeViewStates[state.snappedTargetNodeId];
      if (targetVs != null) {
        endPos = targetVs.leftPort;
      } else {
        endPos = state.currentCursorPosition;
      }
    } else {
      endPos = state.currentCursorPosition;
    }

    // Draw lines from all source nodes to the end position
    for (final sourceId in state.sourceNodeIds) {
      final sourceVs = nodeViewStates[sourceId];
      if (sourceVs == null) continue;

      // Start from source node's right port
      final startPos = sourceVs.rightPort;

      // Draw the relation line
      canvas.drawLine(startPos, endPos, paint);
    }

    // Draw a small circle at the end if not snapped
    if (state.snappedTargetNodeId == null) {
      canvas.drawCircle(endPos, 6, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TempRelationPainter oldDelegate) {
    return oldDelegate.state.currentCursorPosition !=
            state.currentCursorPosition ||
        oldDelegate.state.snappedTargetNodeId != state.snappedTargetNodeId ||
        oldDelegate.state.sourceNodeIds.length != state.sourceNodeIds.length ||
        !oldDelegate.state.sourceNodeIds.containsAll(state.sourceNodeIds);
  }
}

/// Painter for the Marquee Selection box.
class _MarqueePainter extends CustomPainter {
  final MarqueeSelecting state;

  _MarqueePainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(state.startPos, state.currentPos);

    // Fill
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    // Border
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MarqueePainter oldDelegate) {
    return oldDelegate.state.currentPos != state.currentPos;
  }
}
