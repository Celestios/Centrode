import 'package:flutter/material.dart';
import '../../../../models/graph_node.dart';
import '../../../../models/graph_relation.dart';

class MiniMapPainter extends CustomPainter {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final Size viewportSize; // widget pixel dimensions
  final EdgeInsets margins; // elastic margins (L, T, R, B)
  final Rect visibleRect; // current camera view in child coords
  final Color primaryColor;

  MiniMapPainter({
    required this.nodes,
    required this.relations,
    required this.viewportSize,
    required this.margins,
    required this.visibleRect,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return;
    }

    // Total pannable area in child coordinates
    final double totalW = viewportSize.width + margins.left + margins.right;
    final double totalH = viewportSize.height + margins.top + margins.bottom;

    final double scaleX = size.width / totalW;
    final double scaleY = size.height / totalH;

    final double offsetX = (size.width - totalW * scaleX) / 2;
    final double offsetY = (size.height - totalH * scaleY) / 2;

    Offset toMini(double cx, double cy) {
      return Offset(
        (cx + margins.left) * scaleX + offsetX,
        (cy + margins.top) * scaleY + offsetY,
      );
    }

    final Map<String, UiNode> nodeMap = {for (var n in nodes) n.id: n};

    // 1. Draw relations
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (final rel in relations) {
      final from = nodeMap[rel.fromNodeId];
      final to = nodeMap[rel.toNodeId];
      if (from == null || to == null) continue;

      final fromCenter =
          from.position + Offset(from.size.width / 2, from.size.height / 2);
      final toCenter =
          to.position + Offset(to.size.width / 2, to.size.height / 2);

      final start = toMini(fromCenter.dx, fromCenter.dy);
      final end = toMini(toCenter.dx, toCenter.dy);

      if (start.dx >= 0 &&
          start.dx <= size.width &&
          start.dy >= 0 &&
          start.dy <= size.height &&
          end.dx >= 0 &&
          end.dx <= size.width &&
          end.dy >= 0 &&
          end.dy <= size.height) {
        canvas.drawLine(start, end, linePaint);
      }
    }

    // 2. Draw nodes
    for (final node in nodes) {
      final miniPos = toMini(node.position.dx, node.position.dy);
      final double miniWidth = node.size.width * scaleX;
      final double miniHeight = node.size.height * scaleY;

      if (miniPos.dx + miniWidth < 0 ||
          miniPos.dx > size.width ||
          miniPos.dy + miniHeight < 0 ||
          miniPos.dy > size.height) {
        continue;
      }

      final Color bgColor = Color(
        node.resolvedStyle?.bgColor ??
            node.style?.bgColor ??
            primaryColor.toARGB32(),
      );
      final double borderRadius = node.resolvedStyle?.borderRadius ?? 4.0;

      final fillPaint = Paint()..color = bgColor;
      final borderPaint = Paint()
        ..color = (node.resolvedStyle?.strokeColor != null)
            ? Color(node.resolvedStyle!.strokeColor)
            : primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(miniPos.dx, miniPos.dy, miniWidth, miniHeight),
        Radius.circular(borderRadius * scaleX),
      );

      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }

    // 3. Draw viewport rectangle (current camera) – FIXED SIZE
    final viewportTopLeft = toMini(visibleRect.left, visibleRect.top);
    final viewportSizeMini = Size(
      visibleRect.width * scaleX,
      visibleRect.height * scaleY,
    );
    final viewportRect = Rect.fromLTWH(
      viewportTopLeft.dx,
      viewportTopLeft.dy,
      viewportSizeMini.width,
      viewportSizeMini.height,
    ).intersect(Rect.fromLTWH(0, 0, size.width, size.height));

    final viewportFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final viewportBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(viewportRect, viewportFill);
    canvas.drawRect(viewportRect, viewportBorder);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) => true;
}
