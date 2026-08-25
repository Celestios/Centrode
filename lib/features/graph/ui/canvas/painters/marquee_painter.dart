import 'package:flutter/material.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';

/// Painter for the Marquee Selection box.
class MarqueePainter extends CustomPainter {
  final MarqueeSelecting state;

  MarqueePainter({required this.state});

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
  bool shouldRepaint(covariant MarqueePainter oldDelegate) {
    return oldDelegate.state.currentPos != state.currentPos;
  }
}
