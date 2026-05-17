import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/graph_metrics.dart';
import '../../../store/graph_data_controller.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../models/models.dart';
import '../../../presentation/view_state.dart';

class OverlayLayer extends StatelessWidget {
  final CanvasInteractionState interactionState;

  const OverlayLayer({super.key, required this.interactionState});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final renderState = context.watch<NodeRenderState>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 3. Temporary Relation Drag Line (when drawing relation)
        if (interactionState is RelationDrawing)
          Positioned.fill(
            child: CustomPaint(
              painter: _TempRelationPainter(
                state: interactionState as RelationDrawing,
                nodeViewStates: renderState.viewStates,
              ),
            ),
          ),

        // 4. Marquee Selection Box Layer
        if (interactionState is MarqueeSelecting)
          Positioned.fill(
            child: CustomPaint(
              painter: _MarqueePainter(
                state: interactionState as MarqueeSelecting,
              ),
            ),
          ),

        // 5. THE UNIFIED FLOATING TOOLBAR
        if (renderState.selectedEntities.isNotEmpty)
          _buildUnifiedToolbar(context, renderState, dataController),
      ],
    );
  }

  /// Unified toolbar orchestrator that adapts based on selection count.
  /// For single selection, anchors to node position; for multi, anchors to screen center.
  /// Supports both NodeViewState entities and UiRelation entities.
  Widget _buildUnifiedToolbar(
    BuildContext context,
    NodeRenderState renderState,
    GraphDataController data,
  ) {
    final isMulti = renderState.selectedEntities.length > 1;
    final offsetNotifier = isMulti
        ? renderState.multiToolbarOffsetNotifier
        : renderState.toolbarOffsetNotifier;

    // 1. Track ALL selected nodes so the toolbar moves if a multi-selection group is dragged
    // Also track relations and their connected nodes for dynamic anchor calculation
    final List<Listenable> listenables = [offsetNotifier];
    final List<NodeViewState> selectedViewStates = [];
    final List<UiRelation> selectedRelations = [];

    for (final id in renderState.selectedEntities) {
      final vs = renderState.viewStates[id];
      if (vs != null) {
        listenables.add(vs.positionNotifier);
        selectedViewStates.add(vs);
      } else {
        // Fallback: Check if it's a relation
        try {
          final rel = data.relations.firstWhere((r) => r.id == id);
          selectedRelations.add(rel);
          // Listen to connected nodes so toolbar moves when they move
          final sourceVs = renderState.viewStates[rel.fromNodeId];
          final targetVs = renderState.viewStates[rel.toNodeId];
          if (sourceVs != null) listenables.add(sourceVs.positionNotifier);
          if (targetVs != null) listenables.add(targetVs.positionNotifier);
        } catch (_) {}
      }
    }

    final isRelationOnly =
        selectedViewStates.isEmpty && selectedRelations.isNotEmpty && !isMulti;

    // Outer Positioned satisfies Stack constraints, Transform.translate handles dynamic movement
    return Positioned(
      left: 0,
      top: 0,
      child: ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) {
          final offset = offsetNotifier.value;
          Offset anchor = Offset.zero;

          if (selectedViewStates.isNotEmpty) {
            if (isMulti) {
              // 2. Mathematical Bounding Box calculation in Canvas Space
              double minX = double.infinity,
                  minY = double.infinity,
                  maxX = double.negativeInfinity,
                  maxY = double.negativeInfinity;
              for (final vs in selectedViewStates) {
                final rect = vs.rect;
                if (rect.left < minX) minX = rect.left;
                if (rect.top < minY) minY = rect.top;
                if (rect.right > maxX) maxX = rect.right;
                if (rect.bottom > maxY) maxY = rect.bottom;
              }

              if (minX == double.infinity) {
                anchor = offset; // Fallback
              } else {
                // Center horizontally above the bounding box with height offset
                final centerX = minX + (maxX - minX) / 2;
                anchor = Offset(
                  centerX - (AppConfig.toolbar.multiWidth / 2),
                  minY - AppConfig.toolbar.height - 10,
                );
              }
            } else {
              // Single selection fallback
              anchor = selectedViewStates.first.positionNotifier.value;
            }
          } else if (isRelationOnly) {
            // Mathematical midpoint anchor for single relation
            final rel = selectedRelations.first;
            final sourceVs = renderState.viewStates[rel.fromNodeId];
            final targetVs = renderState.viewStates[rel.toNodeId];
            if (sourceVs != null && targetVs != null) {
              final start = sourceVs.rightPort;
              final end = targetVs.leftPort;
              anchor = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
            }
          }

          final position = anchor + offset;

          return Transform.translate(
            offset: position,
            child: GestureDetector(
              onPanUpdate: isMulti
                  ? (d) => offsetNotifier.value += d.delta
                  : null,
              child: _buildToolbarUI(
                onDelete: renderState.deleteSelectedEntities,
                isMulti: isMulti,
                isRelationOnly: isRelationOnly,
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build toolbar UI
  // Three zones for nodes: Drag (left), Link (center), Delete (right)
  // Two zones for relations: Drag (left), Delete (right) - Link is omitted
  Widget _buildToolbarUI({
    required VoidCallback onDelete,
    required bool isMulti,
    bool isRelationOnly = false,
  }) {
    // Dynamically size the toolbar based on available buttons
    double width = isMulti
        ? AppConfig.toolbar.multiWidth
        : AppConfig.toolbar.singleWidth;

    if (isRelationOnly) {
      width = AppConfig.toolbar.buttonWidth * 2; // Only Drag and Delete
    }

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: AppConfig.toolbar.height,
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

            // Conditional Zone 2: Link Button (Omitted for Relations)
            if (!isRelationOnly) ...[
              Container(width: 1, color: Colors.grey.shade300),
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
            ],

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
