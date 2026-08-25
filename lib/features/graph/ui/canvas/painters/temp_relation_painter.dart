import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/store/relation_engine_state.dart';

/// Painter for the temporary relation line during drag.
class TempRelationPainter extends CustomPainter {
  final RelationDrawing state;
  final Map<RawUuid, NodeViewState> nodeViewStates;
  final RelationEngineState relationEngine;

  TempRelationPainter({
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
  bool shouldRepaint(covariant TempRelationPainter oldDelegate) {
    return oldDelegate.state.currentCursorPosition !=
            state.currentCursorPosition ||
        oldDelegate.state.snappedTargetNodeId != state.snappedTargetNodeId ||
        !setEquals(oldDelegate.state.sourceNodeIds, state.sourceNodeIds) ||
        oldDelegate.relationEngine.cacheNotifier.value !=
            relationEngine.cacheNotifier.value;
  }
}
