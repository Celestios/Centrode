import 'package:flutter/material.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';

/// Painter for the OptArea Selection box during drawing.
class OptAreaPainter extends CustomPainter {
  final OptAreaDrawing state;

  OptAreaPainter({required this.state});

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
  bool shouldRepaint(covariant OptAreaPainter oldDelegate) {
    return oldDelegate.state.currentPos != state.currentPos;
  }
}
