import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/graph_controller.dart';
import '../../state/interaction_controller.dart';
import '../../state/canvas_interaction_states.dart';
import '../../domain/models.dart';
import 'node_widget.dart';
import 'relation_painter.dart';
import 'inline_editor_overlay.dart';

/// Extension on Rect to check if one rect fully contains another.
extension RectExtension on Rect {
  bool containsRect(Rect other) =>
      left <= other.left && right >= other.right && top <= other.top && bottom >= other.bottom;
}

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  final TransformationController _transformController = TransformationController();
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
        onNodeDragUpdate: controller.movementNotifier.pulse, // Forces relation repaint during drag
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
    final Offset bottomRight = MatrixUtils.transformPoint(inverse, Offset(size.width, size.height));
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
        return Listener(
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

                        return Stack(
                          children: nodeIds.map((id) {
                            final viewState = controller.allNodeViewStates[id];
                            final node = controller.nodeLookup[id];
                            if (viewState == null || node == null) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              key: ValueKey(id), // Critical for efficient diffing
                              left: 0,
                              top: 0, // Positioned via Transform in NodeWidget
                              child: NodeWidget(
                                viewState: viewState,
                                node: node,
                                isDeleteMenuVisible:
                                    controller.nodeShowingDeleteMenu == node.id,
                                onDelete: () => controller.deleteNode(node.id),
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
                        initialText: controller.nodeLookup[controller.activeEditId!]?.text ??
                            controller.relations.firstWhere((r) => r.id == controller.activeEditId!).label,
                      ),

                    // 3. Temporary Relation Drag Line (when drawing relation)
                    if (state is RelationDrawing)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TempRelationPainter(
                            state: state,
                            nodeViewStates: interactionController.nodeViewStates,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for the temporary relation line during drag.
class _TempRelationPainter extends CustomPainter {
  final RelationDrawing state;
  final Map<String, NodeViewState> nodeViewStates;

  _TempRelationPainter({
    required this.state,
    required this.nodeViewStates,
  });

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
      canvas.drawCircle(
        endPos,
        6,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TempRelationPainter oldDelegate) {
    return oldDelegate.state.currentCursorPosition != state.currentCursorPosition ||
        oldDelegate.state.snappedTargetNodeId != state.snappedTargetNodeId ||
        oldDelegate.state.sourceNodeId != state.sourceNodeId;
  }
}
