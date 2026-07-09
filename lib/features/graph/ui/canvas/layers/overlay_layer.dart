import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../../../presentation/view_state.dart';
import '../widgets/metadata_preview_overlay.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';

class OverlayLayer extends StatelessWidget {
  const OverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataQuery>();
    final renderState = context.watch<NodeRenderState>();
    final interactionController = context.read<InteractionController>();

    return ValueListenableBuilder<CanvasInteractionState>(
      valueListenable: interactionController.state,
      builder: (context, interactionState, _) {
        return UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            // 3. Temporary Relation Drag Line (when drawing relation)
            if (interactionState is RelationDrawing)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TempRelationPainter(
                    state: interactionState,
                    nodeViewStates: renderState.viewStates,
                  ),
                ),
              ),

            // 4. Marquee Selection Box Layer
            if (interactionState is MarqueeSelecting)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MarqueePainter(state: interactionState),
                ),
              ),

            // 6. Metadata Preview Overlay Card
            ListenableBuilder(
              listenable: renderState.hoveredNodeMetadataNotifier,
              builder: (context, _) {
                final hoveredNodeId =
                    renderState.hoveredNodeMetadataNotifier.value;
                if (hoveredNodeId == null) return const SizedBox.shrink();

                final node = dataController.nodeLookup[hoveredNodeId];
                final vs = renderState.viewStates[hoveredNodeId];
                if (node is! InfoUiNode || vs == null) {
                  return const SizedBox.shrink();
                }

                final rect = vs.rect;
                final sphereCenter = Offset(
                  rect.right - AppConfig.node.metadataSphereOffsetFromRight,
                  rect.top + AppConfig.node.metadataSphereOffsetFromTop,
                );

                return Positioned(
                  left:
                      sphereCenter.dx + AppConfig.node.metadataPreviewOffset.dx,
                  top:
                      sphereCenter.dy + AppConfig.node.metadataPreviewOffset.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: MetadataPreviewOverlay(node: node),
                  ),
                );
              },
            ),
          ],
        );
      },
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

    for (final sourceId in state.sourceNodeIds) {
      final sourceVs = nodeViewStates[sourceId];
      if (sourceVs == null) continue;

      final sourcePort = state.sourcePort;

      if (targetVs != null) {
        final targetPort = state.snappedTargetPort;
        final startPos = sourcePort?.position ?? sourceVs.getPortPosition(sourceVs.getClosestPort(targetVs.rect.center).side);
        final endPos = targetPort?.position ?? targetVs.getPortPosition(targetVs.getClosestPort(startPos).side);
        final path = Path()
          ..moveTo(startPos.dx, startPos.dy)
          ..lineTo(endPos.dx, endPos.dy);
        canvas.drawPath(path, paint);
      } else {
        final startPos = sourcePort?.position ?? sourceVs.getPortPosition(sourceVs.getClosestPort(state.currentCursorPosition).side);
        final path = Path()
          ..moveTo(startPos.dx, startPos.dy)
          ..lineTo(state.currentCursorPosition.dx, state.currentCursorPosition.dy);
        canvas.drawPath(path, paint);
        canvas.drawCircle(state.currentCursorPosition, 6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
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
