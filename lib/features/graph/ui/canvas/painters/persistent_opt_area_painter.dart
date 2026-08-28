import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import '../utils/dashed_box_paint_utils.dart';

/// Painter for the Persistent OptArea boundary box, badge, close icon, and 4 resize handles.
class PersistentOptAreaPainter extends CustomPainter {
  final Rect rect;

  PersistentOptAreaPainter({required this.rect});

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

    // Close Cross Icon at top-right inside
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

    // 4 Side Resize Handles
    final handleFillPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    final handleStrokePaint = Paint()
      ..color = Colors.amber.shade900.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Left handle
    final leftHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.left, rect.center.dy),
        width: 6,
        height: UiControlSize.dense,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftHandle, handleFillPaint);
    canvas.drawRRect(leftHandle, handleStrokePaint);

    // Right handle
    final rightHandle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.right, rect.center.dy),
        width: 6,
        height: UiControlSize.dense,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightHandle, handleFillPaint);
    canvas.drawRRect(rightHandle, handleStrokePaint);

    // Top handle
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

    // Bottom handle
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
  bool shouldRepaint(covariant PersistentOptAreaPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
