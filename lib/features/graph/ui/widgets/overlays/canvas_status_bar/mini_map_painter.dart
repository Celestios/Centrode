import 'package:flutter/material.dart';
import '../../../../models/graph_node.dart';
import '../../../../models/graph_relation.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MiniMapPainter extends CustomPainter {
  final List<UiNode> nodes;
  final List<UiRelation> relations;
  final Size viewportSize;
  final EdgeInsets margins;
  final Rect visibleRect;
  final Color primaryColor;

  late final Map<RawUuid, UiNode> _nodeMap;
  late final Paint _linePaint;
  late final Paint _viewportFill;
  late final Paint _viewportBorder;
  late final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  late final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  MiniMapPainter({
    required this.nodes,
    required this.relations,
    required this.viewportSize,
    required this.margins,
    required this.visibleRect,
    required this.primaryColor,
  }) {
    _nodeMap = {for (var n in nodes) n.id: n};
    _linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    _viewportFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    _viewportBorder = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }

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

    // 1. Draw relations
    for (final rel in relations) {
      final from = _nodeMap[rel.fromNodeId];
      final to = _nodeMap[rel.toNodeId];
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
        canvas.drawLine(start, end, _linePaint);
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

      _fillPaint.color = bgColor;
      _borderPaint.color = (node.resolvedStyle?.strokeColor != null)
          ? Color(node.resolvedStyle!.strokeColor)
          : primaryColor.withValues(alpha: 0.3);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(miniPos.dx, miniPos.dy, miniWidth, miniHeight),
        Radius.circular(borderRadius * scaleX),
      );

      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);
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

    canvas.drawRect(viewportRect, _viewportFill);
    canvas.drawRect(viewportRect, _viewportBorder);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.margins != margins ||
        oldDelegate.viewportSize != viewportSize ||
        oldDelegate.nodes.length != nodes.length ||
        (nodes.isNotEmpty && oldDelegate.nodes.first != nodes.first) ||
        oldDelegate.relations.length != relations.length ||
        oldDelegate.primaryColor != primaryColor;
  }
}
