import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import '../utils/dashed_box_paint_utils.dart';

/// Painter for the Persistent OptArea boundary box, badge, close icon, and 4 resize handles.
class PersistentOptAreaPainter extends CustomPainter {
  final Rect rect;

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _closePaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final Paint _handleFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _handleStrokePaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  PersistentOptAreaPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    _fillPaint.color = Colors.amber.withValues(alpha: 0.08);
    canvas.drawRRect(rrect, _fillPaint);

    _strokePaint
      ..color = Colors.amber.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, _strokePaint);

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

    // Close Cross Icon at top-right inside
    _closePaint.color = Colors.amber.withValues(alpha: 0.8);

    final closeCenter = Offset(rect.right - 14, rect.top + 14);
    const closeRadius = 5.0;
    canvas.drawLine(
      closeCenter + const Offset(-closeRadius, -closeRadius),
      closeCenter + const Offset(closeRadius, closeRadius),
      _closePaint,
    );
    canvas.drawLine(
      closeCenter + const Offset(closeRadius, -closeRadius),
      closeCenter + const Offset(-closeRadius, closeRadius),
      _closePaint,
    );

    // 4 Side Resize Handles
    _handleFillPaint.color = Colors.amber;
    _handleStrokePaint
      ..color = Colors.amber.shade900.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Left handle
    final leftHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.left, rect.center.dy),
        width: 6,
        height: UiControlSize.dense,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftHandle, _handleFillPaint);
    canvas.drawRRect(leftHandle, _handleStrokePaint);

    // Right handle
    final rightHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.right, rect.center.dy),
        width: 6,
        height: UiControlSize.dense,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightHandle, _handleFillPaint);
    canvas.drawRRect(rightHandle, _handleStrokePaint);

    // Top handle
    final topHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top),
        width: 20,
        height: 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(topHandle, _handleFillPaint);
    canvas.drawRRect(topHandle, _handleStrokePaint);

    // Bottom handle
    final bottomHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom),
        width: 20,
        height: 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bottomHandle, _handleFillPaint);
    canvas.drawRRect(bottomHandle, _handleStrokePaint);
  }

  @override
  bool shouldRepaint(covariant PersistentOptAreaPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
