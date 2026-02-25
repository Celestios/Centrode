import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/app_config.dart';
import '../../../state/graph_data_controller.dart';
import '../../../state/graph_ui_controller.dart';
import '../../../state/canvas_interaction_states.dart';
import '../../../domain/models.dart';
import '../inline_editor_overlay.dart';

class OverlayLayer extends StatelessWidget {
  final CanvasInteractionState interactionState;
  final Map<String, NodeViewState> nodeViewStates;

  const OverlayLayer({
    super.key,
    required this.interactionState,
    required this.nodeViewStates,
  });

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final uiController = context.watch<GraphUIController>();

    return Stack(
      children: [
        // 2. Absolute Zenith: Transient Editor Overlay
        if (uiController.activeEditId != null)
          InlineEditorOverlay(
            key: ValueKey('editor_${uiController.activeEditId}'),
            entityId: uiController.activeEditId!,
            initialText:
                dataController.nodeLookup[uiController.activeEditId!]?.text ??
                dataController.relations
                    .firstWhere((r) => r.id == uiController.activeEditId!)
                    .label,
          ),

        // 3. Temporary Relation Drag Line (when drawing relation)
        if (interactionState is RelationDrawing)
          Positioned.fill(
            child: CustomPaint(
              painter: _TempRelationPainter(
                state: interactionState as RelationDrawing,
                nodeViewStates: nodeViewStates,
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
        if (uiController.selectedEntities.isNotEmpty)
          _buildUnifiedToolbar(context, uiController, dataController),
      ],
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
    final offsetNotifier = isMulti
        ? ui.multiToolbarOffsetNotifier
        : ui.toolbarOffsetNotifier;

    // 1. Track ALL selected nodes so the toolbar moves if a multi-selection group is dragged
    final List<Listenable> listenables = [offsetNotifier];
    final List<NodeViewState> selectedViewStates = [];

    for (final id in ui.selectedEntities) {
      final vs = data.allNodeViewStates[id];
      if (vs != null) {
        listenables.add(vs.positionNotifier);
        selectedViewStates.add(vs);
      }
    }

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
                  maxX = double.negativeInfinity,
                  minY = double.infinity;

              for (final vs in selectedViewStates) {
                final pos = vs.positionNotifier.value;
                final width = vs.sizeNotifier.value.width > 0
                    ? vs.sizeNotifier.value.width
                    : 150.0;

                if (pos.dx < minX) minX = pos.dx;
                if (pos.dx + width > maxX) maxX = pos.dx + width;
                if (pos.dy < minY) minY = pos.dy; // Top-most Y
              }

              // Top-Center of the selected cluster
              anchor = Offset(
                (minX + maxX) / 2 - (AppConfig.graph.toolbar.multiWidth / 2),
                minY,
              );
            } else {
              // Single selection fallback
              anchor = selectedViewStates.first.positionNotifier.value;
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
                onDelete: ui.deleteSelectedEntities,
                isMulti: isMulti,
              ),
            ),
          );
        },
      ),
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
