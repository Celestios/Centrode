import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/graph_controller.dart';
import '../../state/interaction_controller.dart';
import '../../state/canvas_interaction_states.dart';
import '../../domain/models.dart';
import '../../domain/styling.dart'; // [NEW] For StyleProfile
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

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_handleTransform);

    // Initialize InteractionController after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<GraphController>();
      _interactionController = InteractionController(
        transformController: _transformController,
        nodeViewStates: controller.allNodeViewStates,
        onNodeMove: controller.updateNodePosition,
        onRelationCreate: controller.createRelation,
        onNodeDragUpdate: controller
            .movementNotifier
            .pulse, // Forces relation repaint during drag
        getActiveEditId: () => controller.activeEditId,
        onEnterEditMode: (id) {
          // Directly signal intent to the controller
          controller.enterEditMode(id);
        },
        onCommitActiveEdit: () {
          // The overlay handles actual text commit via onTapOutside.
          // This clears the edit state to dismiss the overlay.
          controller.cancelActiveEdit();
        },
        getRelations: () => controller.relations,
        onCreateNode: (pos) => controller.createNode(UiNodeType.info, pos),
        onNodeResizeEnd: (id, newWidth) {
          // Route directly to existing aesthetic update pipeline
          controller.updateNodeAesthetics(id, StyleProfile(width: newWidth));
        },
        onSelectEntity: controller.selectEntity,
        onSelectEntities: controller.selectEntities,
        getSelectedEntities: () => controller.selectedEntities,
        getToolbarOffset: () => controller.toolbarOffsetNotifier.value,
        updateToolbarOffset: (delta) =>
            controller.toolbarOffsetNotifier.value = delta,
        onDeleteSelectedEntities: controller.deleteSelectedEntities,
        getVisibleNodeIds: () => controller.visibleNodeIds.value,
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
    final controller = context.read<GraphController>();
    final viewport = _calculateCanvasViewport();

    // Check if Viewport has breached the 1.5x Hysteresis Buffer
    if (!_overscanBuffer.containsRect(viewport)) {
      // Expand by 25% on each side (1.5x total area)
      _overscanBuffer = viewport.inflate(viewport.width * 0.25);
      controller.updateVisibleSet(_overscanBuffer);
    }
  }

  /// Calculates the current viewport in canvas coordinates.
  Rect _calculateCanvasViewport() {
    final Matrix4 transform = _transformController.value;

    // Guard against singular matrix to prevent unhandled render exceptions
    if (transform.determinant() == 0.0) return Rect.zero;

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
    final controller = context.watch<GraphController>();
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
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                maxScale: 5.0,
                // Lock viewer if interaction is active (arena circumvention)
                panEnabled: state is CanvasIdle,
                scaleEnabled: state is CanvasIdle,
                child: GestureDetector(
                  // Tap empty space to dismiss menus
                  onTap: () {
                    controller.hideDeleteMenu();
                  },
                  child: SizedBox(
                    width: 5000,
                    height: 5000,
                    child: Stack(
                      children: [
                        // 0. The Relations Layer (Bottom) - Isolated with RepaintBoundary
                        // Uses allNodeViewStates to resolve positions for culled nodes
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: ListenableBuilder(
                              listenable: controller.movementNotifier,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: RelationPainter(
                                    controller.relations,
                                    controller.allNodeViewStates,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // 1. The Nodes Layer - Only renders visible nodes via ValueListenableBuilder
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: controller.visibleNodeIds,
                          builder: (context, visibleIds, _) {
                            // If no visible set calculated yet, render all nodes
                            final nodeIds = visibleIds.isEmpty
                                ? controller.nodes.map((n) => n.id).toList()
                                : visibleIds.toList();

                            // Update z-order in InteractionController
                            interactionController.updateZOrder(nodeIds);

                            // [FIX]: Defensive Data Projection - Filter orphaned IDs before Widget inflation
                            final validNodeIds = nodeIds.where(
                              (id) =>
                                  controller.allNodeViewStates.containsKey(
                                    id,
                                  ) &&
                                  controller.nodeLookup.containsKey(id),
                            );

                            return Stack(
                              children: validNodeIds.map((id) {
                                // Safe to force-unwrap because of the strict pre-filter above
                                final viewState =
                                    controller.allNodeViewStates[id]!;
                                final node = controller.nodeLookup[id]!;

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
                                        controller.nodeShowingDeleteMenu ==
                                        node.id,
                                    onDelete: () =>
                                        controller.deleteNode(node.id),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        // 2. Absolute Zenith: Transient Editor Overlay
                        // Unified overlay for both nodes and relations
                        if (controller.activeEditId != null)
                          InlineEditorOverlay(
                            key: ValueKey('editor_${controller.activeEditId}'),
                            entityId: controller.activeEditId!,
                            initialText:
                                controller
                                    .nodeLookup[controller.activeEditId!]
                                    ?.text ??
                                controller.relations
                                    .firstWhere(
                                      (r) => r.id == controller.activeEditId!,
                                    )
                                    .label,
                          ),

                        // 2.5: The Single-Node Floating Toolbar
                        if (controller.selectedEntities.length == 1 &&
                            controller.allNodeViewStates.containsKey(
                              controller.selectedEntities.first,
                            ))
                          ValueListenableBuilder<Offset>(
                            valueListenable: controller.toolbarOffsetNotifier,
                            builder: (context, tbOffset, _) {
                              final vs =
                                  controller.allNodeViewStates[controller
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
                                          controller.deleteSelectedEntities,
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
            if (controller.selectedEntities.length > 1)
              ValueListenableBuilder<Offset>(
                valueListenable: controller.multiToolbarOffsetNotifier,
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
                        controller.multiToolbarOffsetNotifier.value +=
                            details.delta;
                      },
                      child: _buildToolbarUI(
                        onDrag:
                            () {}, // Empty to satisfy signature, pan handled by GestureDetector above
                        onDelete: controller.deleteSelectedEntities,
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

    // Start from source node's right center (port position)
    final sourceRect = sourceVs.rect;
    final startPos = sourceRect.centerRight;

    // End position - either snapped target's left center or cursor position
    Offset endPos;
    if (state.snappedTargetNodeId != null) {
      final targetVs = nodeViewStates[state.snappedTargetNodeId];
      if (targetVs != null) {
        endPos = targetVs.rect.centerLeft;
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
