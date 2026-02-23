import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/app_config.dart';
import '../../state/graph_data_controller.dart';
import '../../state/graph_ui_controller.dart';
import '../../state/interaction_controller.dart';
import '../../state/canvas_interaction_states.dart';
import '../../domain/models.dart';
import '../../domain/styling.dart';
import 'node_widget.dart';
import 'relation_painter.dart';
import 'inline_editor_overlay.dart';

/// Extension on Rect to check if one rect fully contains another.
extension RectExtension on Rect {
  bool containsRect(Rect other) =>
      left <= other.left &&
      right >= other.right &&
      top <= other.top &&
      bottom >= other.bottom;
}

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  final TransformationController _transformController =
      TransformationController();
  Rect _overscanBuffer = Rect.zero;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas'); // [NEW]

  @override
  void initState() {
    super.initState();
    _log.info('Initializing GraphCanvas and tracking transform mutations.');
    _transformController.addListener(_handleTransform);

    // Initialize InteractionController after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataController = context.read<GraphDataController>();
      final uiController = context.read<GraphUIController>();

      _interactionController = InteractionController(
        transformController: _transformController,
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
    _transformController.removeListener(_handleTransform);
    _transformController.dispose();
    _interactionController?.dispose();
    super.dispose();
  }

  /// Handles transform changes (pan/zoom) and updates visible node set.
  void _handleTransform() {
    final uiController = context.read<GraphUIController>();
    final viewport = _calculateCanvasViewport();

    // Check if Viewport has breached the 1.5x Hysteresis Buffer
    if (!_overscanBuffer.containsRect(viewport)) {
      // Expand by 25% on each side (1.5x total area)
      _overscanBuffer = viewport.inflate(
        viewport.width * AppConfig.graph.canvas.overscanRatio,
      );
      uiController.updateVisibleSet(_overscanBuffer);
    }
  }

  /// Calculates the current viewport in canvas coordinates.
  Rect _calculateCanvasViewport() {
    final Matrix4 transform = _transformController.value;

    // Guard against singular matrix to prevent unhandled render exceptions
    if (transform.determinant() == 0.0) {
      _log.severe(
        'Singular matrix detected in canvas transform (Scale = 0). Aborting viewport calculation.',
      ); // [NEW]
      return Rect.zero;
    }

    final Matrix4 inverse = Matrix4.inverted(transform);
    final Size size = MediaQuery.of(context).size;

    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(size.width, size.height),
    );
    return Rect.fromPoints(topLeft, bottomRight);
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
              child: InteractiveViewer(
                transformationController: _transformController,
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
                                ? dataController.nodes.map((n) => n.id).toList()
                                : visibleIds.toList();

                            // Update z-order in InteractionController
                            interactionController.updateZOrder(nodeIds);

                            // [FIX]: Defensive Data Projection - Filter orphaned IDs before Widget inflation
                            final validNodeIds = nodeIds.where(
                              (id) =>
                                  dataController.allNodeViewStates.containsKey(
                                    id,
                                  ) &&
                                  dataController.nodeLookup.containsKey(id),
                            );

                            return Stack(
                              children: validNodeIds.map((id) {
                                // Safe to force-unwrap because of the strict pre-filter above
                                final viewState =
                                    dataController.allNodeViewStates[id]!;
                                final node = dataController.nodeLookup[id]!;

                                return Positioned(
                                  key: ValueKey(
                                    id,
                                  ), // Critical for efficient diffing
                                  left: 0,
                                  top:
                                      0, // Positioned via Transform in NodeWidget
                                  child: NodeWidget(
                                    viewState: viewState,
                                    node: node,
                                    isDeleteMenuVisible:
                                        uiController.nodeShowingDeleteMenu ==
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
                                      (r) => r.id == uiController.activeEditId!,
                                    )
                                    .label,
                          ),

                        // 2.5: The Single-Node Floating Toolbar
                        if (uiController.selectedEntities.length == 1 &&
                            dataController.allNodeViewStates.containsKey(
                              uiController.selectedEntities.first,
                            ))
                          ValueListenableBuilder<Offset>(
                            valueListenable: uiController.toolbarOffsetNotifier,
                            builder: (context, tbOffset, _) {
                              final vs =
                                  dataController.allNodeViewStates[uiController
                                      .selectedEntities
                                      .first]!;
                              return ListenableBuilder(
                                listenable: vs.positionNotifier,
                                builder: (context, _) {
                                  final tbPos =
                                      vs.positionNotifier.value + tbOffset;
                                  return Positioned(
                                    left: tbPos.dx,
                                    top: tbPos.dy,
                                    child: _buildToolbarUI(
                                      onDrag:
                                          null, // Drag handled by FSM ToolbarDragging
                                      onDelete:
                                          uiController.deleteSelectedEntities,
                                    ),
                                  );
                                },
                              );
                            },
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
              ),
            ),

            // 5. Absolute Top UI Layer (Screen Space) - The Global Multi-Toolbar
            if (uiController.selectedEntities.length > 1)
              ValueListenableBuilder<Offset>(
                valueListenable: uiController.multiToolbarOffsetNotifier,
                builder: (context, offset, _) {
                  return Positioned(
                    // Anchor to top center of screen, offset by the Notifier
                    top: offset.dy,
                    left:
                        (MediaQuery.of(context).size.width / 2) -
                        50 +
                        offset.dx,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        uiController.multiToolbarOffsetNotifier.value +=
                            details.delta;
                      },
                      child: _buildToolbarUI(
                        onDrag:
                            () {}, // Empty to satisfy signature, pan handled by GestureDetector above
                        onDelete: uiController.deleteSelectedEntities,
                        isMulti: true,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // Helper method to build toolbar UI
  Widget _buildToolbarUI({
    required Function? onDrag,
    required VoidCallback onDelete,
    bool isMulti = false,
  }) {
    return Container(
      width: isMulti
          ? 100
          : 80, // Slightly wider for multi to show an indicator
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: isMulti ? 0.8 : 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(
                isMulti ? Icons.library_add_check : Icons.drag_indicator,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter for the temporary relation line during drag.
class _TempRelationPainter extends CustomPainter {
  final RelationDrawing state;
  final Map<String, NodeViewState> nodeViewStates;

  _TempRelationPainter({required this.state, required this.nodeViewStates});

  @override
  void paint(Canvas canvas, Size size) {
    final sourceVs = nodeViewStates[state.sourceNodeId];
    if (sourceVs == null) return;

    final paint = Paint()
      ..color = state.snappedTargetNodeId != null
          ? Colors.green
          : Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from source node's right port
    final startPos = sourceVs.rightPort; // [REFACTORED]

    // End position - either snapped target's left port or cursor position
    Offset endPos;
    if (state.snappedTargetNodeId != null) {
      final targetVs = nodeViewStates[state.snappedTargetNodeId];
      if (targetVs != null) {
        endPos = targetVs.leftPort; // [REFACTORED]
      } else {
        endPos = state.currentCursorPosition;
      }
    } else {
      endPos = state.currentCursorPosition;
    }

    // Draw the relation line
    canvas.drawLine(startPos, endPos, paint);

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
        oldDelegate.state.sourceNodeId != state.sourceNodeId;
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
