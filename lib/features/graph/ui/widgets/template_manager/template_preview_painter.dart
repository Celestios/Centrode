import 'package:flutter/material.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';

class TemplatePreviewPainter extends CustomPainter {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final bool isDark;

  TemplatePreviewPainter({
    required this.nodes,
    required this.relations,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final Map<RawUuid, Rect> nodeRects = {};

    for (final node in nodes) {
      final double nx = node.position.dx;
      final double ny = node.position.dy;
      final double nw = node.previewSize.width;
      final double nh = node.previewSize.height;

      final rect = Rect.fromLTWH(nx, ny, nw, nh);
      nodeRects[node.id] = rect;

      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }

    if (minX == double.infinity) return;

    final double groupWidth = maxX - minX;
    final double groupHeight = maxY - minY;

    const double padding = 6.0;
    final double targetWidth = size.width - (padding * 2);
    final double targetHeight = size.height - (padding * 2);

    double scale = 1.0;
    if (groupWidth > 0 || groupHeight > 0) {
      final double scaleX = groupWidth > 0
          ? targetWidth / groupWidth
          : double.infinity;
      final double scaleY = groupHeight > 0
          ? targetHeight / groupHeight
          : double.infinity;
      scale = scaleX < scaleY ? scaleX : scaleY;
      if (scale > 0.4) scale = 0.4;
    }

    final double offsetX =
        padding + (targetWidth - (groupWidth * scale)) / 2 - minX * scale;
    final double offsetY =
        padding + (targetHeight - (groupHeight * scale)) / 2 - minY * scale;

    Offset transform(Offset p) {
      return Offset(p.dx * scale + offsetX, p.dy * scale + offsetY);
    }

    final relationPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final startRect = nodeRects[rel.fromNodeId];
      final endRect = nodeRects[rel.toNodeId];
      if (startRect != null && endRect != null) {
        final startCenter = transform(startRect.center);
        final endCenter = transform(endRect.center);
        canvas.drawLine(startCenter, endCenter, relationPaint);
      }
    }

    for (final node in nodes) {
      final rect = nodeRects[node.id];
      if (rect != null) {
        final scaledRect = Rect.fromPoints(
          transform(rect.topLeft),
          transform(rect.bottomRight),
        );

        final nodePaint = Paint()
          ..color = node.defaultPreviewColor
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.15)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke;

        final rrect = RRect.fromRectAndRadius(
          scaledRect,
          const Radius.circular(3.0),
        );
        canvas.drawRRect(rrect, nodePaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TemplatePreviewPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.relations != relations ||
        oldDelegate.isDark != isDark;
  }
}
