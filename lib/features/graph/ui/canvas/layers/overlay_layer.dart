import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../presentation/graph_metrics.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../models/models.dart';
import '../../../presentation/view_state.dart';
import '../metadata_preview_overlay.dart';

class OverlayLayer extends StatelessWidget {
  final CanvasInteractionState interactionState;

  const OverlayLayer({super.key, required this.interactionState});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataQuery>();
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

        // 6. Metadata Preview Overlay Card
        ListenableBuilder(
          listenable: renderState.hoveredNodeMetadataNotifier,
          builder: (context, _) {
            final hoveredNodeId = renderState.hoveredNodeMetadataNotifier.value;
            if (hoveredNodeId == null) return const SizedBox.shrink();

            final node = dataController.nodeLookup[hoveredNodeId];
            final vs = renderState.viewStates[hoveredNodeId];
            if (node is! InfoUiNode || vs == null) return const SizedBox.shrink();

            final rect = vs.rect;
            final sphereCenter = Offset(
              rect.right - AppConfig.node.metadataSphereOffsetFromRight,
              rect.top + AppConfig.node.metadataSphereOffsetFromTop,
            );

            return Positioned(
              left: sphereCenter.dx + AppConfig.node.metadataPreviewOffset.dx,
              top: sphereCenter.dy + AppConfig.node.metadataPreviewOffset.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.0),
                child: MetadataPreviewOverlay(node: node),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Unified toolbar orchestrator that adapts based on selection count.
  /// For single selection, anchors to node position; for multi, anchors to screen center.
  /// Supports both NodeViewState entities and UiRelation entities.
  Widget _buildUnifiedToolbar(
    BuildContext context,
    NodeRenderState renderState,
    GraphDataQuery data,
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

          if (selectedViewStates.isNotEmpty || selectedRelations.isNotEmpty) {
            anchor = renderState.calculateToolbarAnchor(renderState.selectedEntities) ?? Offset.zero;
          }

          final position = anchor + offset;

          final nodeIds = renderState.selectedEntities
              .where((id) => data.nodeLookup.containsKey(id))
              .toList();
          final canSaveTemplate = nodeIds.isNotEmpty;
          final String? singleNodeId = (!isMulti && nodeIds.length == 1) ? nodeIds.first : null;

          return Transform.translate(
            offset: position,
            child: GestureDetector(
              onPanUpdate: isMulti
                  ? (d) => offsetNotifier.value += d.delta
                  : null,
              child: _buildToolbarUI(
                context: context,
                onDelete: renderState.deleteSelectedEntities,
                isMulti: isMulti,
                isRelationOnly: isRelationOnly,
                canSaveTemplate: canSaveTemplate,
                singleNodeId: singleNodeId,
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
    required BuildContext context,
    required VoidCallback onDelete,
    required bool isMulti,
    bool isRelationOnly = false,
    bool canSaveTemplate = false,
    String? singleNodeId,
  }) {
    // Dynamically size the toolbar based on available buttons
    double width = isMulti
        ? AppConfig.toolbar.multiWidth
        : AppConfig.toolbar.singleWidth;

    if (isRelationOnly) {
      width = AppConfig.toolbar.buttonWidth * 2; // Only Drag and Delete
    } else if (canSaveTemplate) {
      width += AppConfig.toolbar.buttonWidth;
    }

    final isSingleNode = singleNodeId != null;
    final height = isSingleNode
        ? AppConfig.toolbar.height * 2
        : AppConfig.toolbar.height;

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blueAccent.withValues(alpha: isMulti ? 0.8 : 0.3),
          ),
        ),
        child: isSingleNode
            ? Column(
                children: [
                  // Row 1 (Top): Formatting (Decrease Size, Increase Size, Toggle Font, Cycle Color)
                  SizedBox(
                    height: AppConfig.toolbar.height - 0.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Tooltip(
                              message: "Decrease Font Size",
                              child: Icon(
                                Icons.remove_rounded,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade200),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Tooltip(
                              message: "Increase Font Size",
                              child: Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade200),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Tooltip(
                              message: "Toggle Font Family",
                              child: Icon(
                                Icons.text_fields_rounded,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade200),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Tooltip(
                              message: "Cycle Text Color",
                              child: Icon(
                                Icons.palette_outlined,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.grey.shade300),
                  // Row 2 (Bottom): Existing controls
                  SizedBox(
                    height: AppConfig.toolbar.height - 0.5,
                    child: Row(
                      children: [
                        // Drag Handle
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
                        // Link Button
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.link,
                              size: 20,
                              color: Colors.blueAccent.shade700,
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade300),
                        // Save as Template
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.bookmark_add_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey.shade300),
                        // Delete Button
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
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
                        child: Icon(
                          Icons.link,
                          size: 20,
                          color: Colors.blueAccent.shade700,
                        ),
                      ),
                    ),
                  ],

                  // Save as Template Button
                  if (canSaveTemplate) ...[
                    Container(width: 1, color: Colors.grey.shade300),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          Icons.bookmark_add_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],

                  Container(width: 1, color: Colors.grey.shade300),
                  // Zone 3: Delete Button
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red.shade400,
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

    final targetVs = state.snappedTargetNodeId != null
        ? nodeViewStates[state.snappedTargetNodeId]
        : null;

    if (targetVs != null) {
      // Snapped to a target node: Draw optimal path from each source to target
      for (final sourceId in state.sourceNodeIds) {
        final sourceVs = nodeViewStates[sourceId];
        if (sourceVs == null) continue;

        final closest = NodeViewState.getClosestPortsBetween(sourceVs, targetVs);
        canvas.drawLine(closest.startPos, closest.endPos, paint);
      }
    } else {
      // Not snapped: Draw from closest source port to cursor position
      final endPos = state.currentCursorPosition;
      for (final sourceId in state.sourceNodeIds) {
        final sourceVs = nodeViewStates[sourceId];
        if (sourceVs == null) continue;

        final startPos = sourceVs.getClosestPort(endPos).position;
        canvas.drawLine(startPos, endPos, paint);
      }

      // Draw a small circle at the end if not snapped
      canvas.drawCircle(endPos, 6, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TempRelationPainter oldDelegate) {
    return oldDelegate.state.currentCursorPosition !=
            state.currentCursorPosition ||
        oldDelegate.state.snappedTargetNodeId != state.snappedTargetNodeId ||
        !setEquals(oldDelegate.state.sourceNodeIds, state.sourceNodeIds);
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
