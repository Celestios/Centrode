import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../utils/container_paint_utils.dart';

/// Renderer for [FrameUiNode] representing a flat 2D spatial grouping box on the canvas.
class FrameNodeRenderer {
  const FrameNodeRenderer._();

  static Color getFrameBaseColor(FrameUiNode node, NodeStyle resolvedStyle) =>
      getDashedBoxBaseColor(resolvedStyle, const Color(0xFFBCAAA4));

  /// Paints a dashed grouping frame with top-left type badge inside and top-middle node title outside.
  static void paintFrameCard({
    required Canvas canvas,
    required FrameUiNode node,
    required NodeStyle resolvedStyle,
    required Rect rect,
    required double fontScale,
    bool isEditing = false,
  }) {
    final baseColor = getFrameBaseColor(node, resolvedStyle);
    final borderRadius = resolvedStyle.borderRadius > 0 ? resolvedStyle.borderRadius : 8.0;
    final strokeWidth = resolvedStyle.strokeWidth > 0 ? resolvedStyle.strokeWidth.toDouble() : 1.5;

    // 1. Paint the frame with top-left type badge inside and side resize handles
    DashedBoxPaintUtils.paintDashedBox(
      canvas,
      rect,
      baseColor: baseColor,
      borderRadius: borderRadius,
      strokeWidth: strokeWidth,
      dashWidth: 14.0,
      dashSpace: 8.0,
      badgeText: 'FRAME',
      badgeCenteredOutside: false,
      showResizeHandles: true,
      badgeOffset: const Offset(12.0, 12.0),
      scale: fontScale,
    );

    // 2. Paint the node title at top-middle outside (when not editing)
    if (!isEditing) {
      final titleText = node.title.trim().isNotEmpty ? node.title.trim() : 'title';
      final span = TextSpan(
        text: titleText,
        style: TextStyle(
          color: const Color(0xFFEEEEEE),
          fontSize: (13.0 * fontScale).clamp(11.0, 16.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();

      final pillWidth = tp.width + 16.0 * fontScale;
      final pillHeight = tp.height + 6.0 * fontScale;
      final pillLeft = rect.center.dx - (pillWidth / 2.0);
      final pillTop = rect.top - pillHeight - 4.0 * fontScale;

      final pillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
        Radius.circular(6.0 * fontScale),
      );

      canvas.drawRRect(
        pillRRect,
        Paint()..color = const Color(0xFF1E1E24).withValues(alpha: 0.85),
      );
      canvas.drawRRect(
        pillRRect,
        Paint()
          ..color = baseColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      tp.paint(
        canvas,
        Offset(
          pillLeft + 8.0 * fontScale,
          pillTop + 3.0 * fontScale,
        ),
      );
      tp.dispose();
    }
  }
}
