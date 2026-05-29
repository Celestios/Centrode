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
import '../../widgets/overlays/vertical_context_toolbar.dart';

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
