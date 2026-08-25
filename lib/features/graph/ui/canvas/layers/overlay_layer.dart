import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../engine/config.dart';
import '../../../store/graph_data_query.dart';
import '../../../store/relation_engine_state.dart';
import '../../../presentation/node_render_state.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/interaction_engine.dart';
import '../../../models/models.dart';
import '../../../presentation/view_state.dart';
import '../widgets/metadata_preview_overlay.dart';
import '../widgets/relation_label_morph_editor.dart';
import '../utils/dashed_box_paint_utils.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';

class OverlayLayer extends StatelessWidget {
  const OverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataQuery>();
    final renderState = context.read<NodeRenderState>();
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
                child: ValueListenableBuilder<int>(
                  valueListenable: dataController.relationEngine.cacheNotifier,
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: _TempRelationPainter(
                        state: interactionState,
                        nodeViewStates: renderState.viewStates,
                        relationEngine: dataController.relationEngine,
                      ),
                    );
                  },
                ),
              ),

            // 4. Marquee Selection Box Layer
            if (interactionState is MarqueeSelecting)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MarqueePainter(state: interactionState),
                ),
              ),

            // 5. Persistent OptArea Box Layer
            ValueListenableBuilder<Rect?>(
              valueListenable: dataController.optAreaNotifier,
              builder: (context, persistentOptRect, _) {
                if (persistentOptRect == null) return const SizedBox.shrink();
                return _PersistentOptAreaWidget(rect: persistentOptRect);
              },
            ),

            // 6. OptArea Drawing Box Layer
            if (interactionState is OptAreaDrawing)
              Positioned.fill(
                child: CustomPaint(
                  painter: _OptAreaPainter(state: interactionState),
                ),
              ),

            // 7. Frame Drawing Live Box Layer
            if (interactionState is FrameDrawing)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FrameDrawingPainter(state: interactionState),
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

                // Scale the vertical floating clearance offset proportionally with node height
                final scaledOffsetY = (AppConfig.node.metadataPreviewOffset.dy * (rect.height / 80.0)).clamp(-72.0, -24.0);

                return Positioned(
                  left:
                      sphereCenter.dx + AppConfig.node.metadataPreviewOffset.dx,
                  top:
                      sphereCenter.dy + scaledOffsetY,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: MetadataPreviewOverlay(
                      node: node,
                      nodeWidth: rect.width,
                    ),
                  ),
                );
              },
            ),

            // 7. Active Relation Label Morph Editor (renders on top of all nodes)
            ListenableBuilder(
              listenable: renderState,
              builder: (context, _) {
                final activeEditId = renderState.activeEditId;
                if (activeEditId == null) return const SizedBox.shrink();

                final editedRel = dataController.relations
                    .where((r) => r.id == activeEditId)
                    .firstOrNull;
                if (editedRel == null) return const SizedBox.shrink();

                final cached =
                    dataController.relationEngine.cache[editedRel.id];
                if (cached == null) return const SizedBox.shrink();

                final labelPos = Offset(
                  cached.labelPosition.x,
                  cached.labelPosition.y,
                );

                return RelationLabelMorphEditor(
                  relation: editedRel,
                  labelCenter: labelPos,
                  queryController: dataController,
                  uiController: renderState,
                  interactionContext: interactionController.environment,
                  onCommit: (verb) {
                    renderState.commitEntityText(editedRel.id, verb);
                  },
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
  final Map<RawUuid, NodeViewState> nodeViewStates;
  final RelationEngineState relationEngine;

  _TempRelationPainter({
    required this.state,
    required this.nodeViewStates,
    required this.relationEngine,
  });

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

      final scale = sourceVs.currentScale;
      final cursorRadius = 6.0 * scale;
      final strokePaint = paint..strokeWidth = 2.0 * scale;

      final sourcePort = state.sourcePort;

      if (targetVs != null) {
        final cached = relationEngine.previewCache[sourceId];

        if (cached != null && cached.pathPoints.length >= 2) {
          final path = Path()
            ..moveTo(cached.pathPoints.first.x, cached.pathPoints.first.y);
          for (int i = 1; i < cached.pathPoints.length; i++) {
            path.lineTo(cached.pathPoints[i].x, cached.pathPoints[i].y);
          }
          canvas.drawPath(path, strokePaint);
        } else {
          final targetPort = state.snappedTargetPort;
          final startPos =
              sourcePort?.position ??
              sourceVs.getPortPosition(
                sourceVs.getClosestPort(targetVs.rect.center).side,
              );
          final endPos =
              targetPort?.position ??
              targetVs.getPortPosition(targetVs.getClosestPort(startPos).side);
          canvas.drawLine(startPos, endPos, strokePaint);
        }
      } else {
        final startPos =
            sourcePort?.position ??
            sourceVs.getPortPosition(
              sourceVs.getClosestPort(state.currentCursorPosition).side,
            );
        canvas.drawLine(startPos, state.currentCursorPosition, strokePaint);
        canvas.drawCircle(
          state.currentCursorPosition,
          cursorRadius,
          strokePaint..style = PaintingStyle.fill,
        );
        strokePaint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TempRelationPainter oldDelegate) {
    return oldDelegate.state.currentCursorPosition !=
            state.currentCursorPosition ||
        oldDelegate.state.snappedTargetNodeId != state.snappedTargetNodeId ||
        !setEquals(oldDelegate.state.sourceNodeIds, state.sourceNodeIds) ||
        oldDelegate.relationEngine.cacheNotifier.value !=
            relationEngine.cacheNotifier.value;
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

/// Painter for the OptArea Selection box.
class _OptAreaPainter extends CustomPainter {
  final OptAreaDrawing state;

  _OptAreaPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(state.startPos, state.currentPos);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Fill
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.amberAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _OptAreaPainter oldDelegate) {
    return oldDelegate.state.currentPos != state.currentPos;
  }
}

/// Widget for the Persistent OptArea box layer.
class _PersistentOptAreaWidget extends StatelessWidget {
  final Rect rect;

  const _PersistentOptAreaWidget({required this.rect});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _PersistentOptAreaPainter(rect: rect),
      ),
    );
  }
}

/// Painter for the Persistent OptArea boundary box, badge, close icon, and 4 resize handles.
class _PersistentOptAreaPainter extends CustomPainter {
  final Rect rect;

  _PersistentOptAreaPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Fill
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.amber.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.amber.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // OPT AREA Text Badge at top-left
    DashedBoxPaintUtils.paintTopLeftBadge(
      canvas,
      rect,
      1.0,
      text: 'OPT AREA',
      textColor: Colors.amber.shade200,
      badgeBgColor: Colors.amber.shade900.withValues(alpha: 0.75),
      borderColor: Colors.amber.withValues(alpha: 0.4),
      offset: const Offset(4.0, 4.0),
    );

    // Close Cross Icon at top-right inside (same amber edge color, no background)
    final closePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final closeCenter = Offset(rect.right - 14, rect.top + 14);
    const closeRadius = 5.0;
    canvas.drawLine(
      closeCenter + const Offset(-closeRadius, -closeRadius),
      closeCenter + const Offset(closeRadius, closeRadius),
      closePaint,
    );
    canvas.drawLine(
      closeCenter + const Offset(closeRadius, -closeRadius),
      closeCenter + const Offset(-closeRadius, closeRadius),
      closePaint,
    );

    // 4 Side Resize Handles (Pill/Bar grips on left, right, top, bottom edges)
    final handleFillPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    final handleStrokePaint = Paint()
      ..color = Colors.amber.shade900.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Left handle (vertical pill at center of left edge)
    final leftHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.left, rect.center.dy),
        width: 6,
        height: 20,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftHandle, handleFillPaint);
    canvas.drawRRect(leftHandle, handleStrokePaint);

    // Right handle (vertical pill at center of right edge)
    final rightHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.right, rect.center.dy),
        width: 6,
        height: 20,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightHandle, handleFillPaint);
    canvas.drawRRect(rightHandle, handleStrokePaint);

    // Top handle (horizontal pill at center of top edge)
    final topHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top),
        width: 20,
        height: 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(topHandle, handleFillPaint);
    canvas.drawRRect(topHandle, handleStrokePaint);

    // Bottom handle (horizontal pill at center of bottom edge)
    final bottomHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom),
        width: 20,
        height: 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bottomHandle, handleFillPaint);
    canvas.drawRRect(bottomHandle, handleStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _PersistentOptAreaPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}

class _FrameDrawingPainter extends CustomPainter {
  final FrameDrawing state;

  _FrameDrawingPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final rawRect = Rect.fromPoints(state.startPos, state.currentPos);
    final rect = Rect.fromLTRB(
      math.min(rawRect.left, rawRect.right),
      math.min(rawRect.top, rawRect.bottom),
      math.max(rawRect.left, rawRect.right),
      math.max(rawRect.top, rawRect.bottom),
    );

    DashedBoxPaintUtils.paintDashedBox(
      canvas,
      rect,
      baseColor: const Color(0xFFBCAAA4),
      borderRadius: 8.0,
      strokeWidth: 1.5,
      dashWidth: 14.0,
      dashSpace: 8.0,
      badgeText: 'FRAME',
    );
  }

  @override
  bool shouldRepaint(covariant _FrameDrawingPainter oldDelegate) {
    return oldDelegate.state.startPos != state.startPos ||
        oldDelegate.state.currentPos != state.currentPos;
  }
}
