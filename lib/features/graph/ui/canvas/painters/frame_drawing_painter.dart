import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import '../utils/dashed_box_paint_utils.dart';

/// Painter for frame drawing live box layer.
class FrameDrawingPainter extends CustomPainter {
  final FrameDrawing state;

  FrameDrawingPainter({required this.state});

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
      strokeWidth: UiStrokeWidth.thick,
      dashWidth: 14.0,
      dashSpace: 8.0,
      badgeText: 'FRAME',
    );
  }

  @override
  bool shouldRepaint(covariant FrameDrawingPainter oldDelegate) {
    return oldDelegate.state.startPos != state.startPos ||
        oldDelegate.state.currentPos != state.currentPos;
  }
}
