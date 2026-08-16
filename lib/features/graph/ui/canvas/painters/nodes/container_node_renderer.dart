import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../presentation/strategies/node_layout_strategy.dart';
import '../../../../presentation/strategies/node_style_strategy.dart';
import '../../../../presentation/strategies/relation_style_strategy.dart';
import '../../../../store/relation_engine_state.dart';
import '../../utils/container_paint_utils.dart';
import 'shape_node_renderer.dart';
import 'text_node_renderer.dart';

class ContainerNodeRenderer {
  const ContainerNodeRenderer();

  static void paintContainerCard({
    required Canvas canvas,
    required ContainerUiNode node,
    required NodeStyle resolvedStyle,
    required Rect rect,
    required double w,
    required double h,
    required double screenWidth,
    required double fontScale,
    required Color? containerBaseColor,
    required Color? containerBorderColor,
    required Color? containerBgColor,
    required Map<dynamic, UiNode> nodeLookup,
    required Iterable<UiRelation>? relations,
    required RelationEngineState? relationEngine,
  }) {
    final aspectRatio = h / (w > 0 ? w : 1.0);
    final internalW = 1600.0;
    final internalH = 1600.0 * aspectRatio;
    final sx = w / internalW;
    final sy = h / internalH;
    final internalRect = Rect.fromLTWH(0, 0, internalW, internalH);
    final internalRRect =
        RRect.fromRectAndRadius(internalRect, const Radius.circular(16.0));

    final bgPaint = Paint();
    final borderPaint = Paint();

    if (node.isClosed) {
      if (screenWidth < 80.0) {
        // Stage 1: Centered title in closed card
        paintContainerTitleCentered(
          canvas,
          rect,
          node.title,
          resolvedStyle,
          1.0,
          fontScale,
        );
      } else {
        // Stage 2: Approach Zone (Title fades out, internal dashed border + tag + inside preview fade in)
        final double t =
            ((screenWidth - 80.0) / (180.0 - 80.0)).clamp(0.0, 1.0);
        paintContainerTitleCentered(
          canvas,
          rect,
          node.title,
          resolvedStyle,
          1.0 - t,
          fontScale,
        );

        canvas.save();
        canvas.scale(sx, sy);
        if (containerBgColor != null) {
          bgPaint.color =
              containerBgColor.withValues(alpha: containerBgColor.a * t);
          canvas.drawRRect(internalRRect, bgPaint);
        }
        paintContainerInsidePreview(
          canvas: canvas,
          containerNode: node,
          internalRect: internalRect,
          internalRRect: internalRRect,
          opacity: t,
          nodeLookup: nodeLookup,
          relations: relations,
          relationEngine: relationEngine,
        );
        borderPaint
          ..color = (containerBorderColor ?? const Color(0xFF64B5F6))
              .withValues(alpha: 0.85 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(resolvedStyle.strokeWidth.toDouble(), 2.0);
        drawDashedRRect(canvas, internalRRect, borderPaint, 16.0, 10.0);
        paintContainerTopLeftTag(
          canvas,
          internalRect,
          1.0,
          containerBaseColor ?? const Color(0xFF64B5F6),
          opacity: t,
        );
        canvas.restore();
      }
    } else {
      // Stage 3: Open Container — dashed border + background + inside preview + top-left tag in internal coordinates
      canvas.save();
      canvas.scale(sx, sy);
      if (containerBgColor != null) {
        bgPaint.color = containerBgColor;
        canvas.drawRRect(internalRRect, bgPaint);
      }
      paintContainerInsidePreview(
        canvas: canvas,
        containerNode: node,
        internalRect: internalRect,
        internalRRect: internalRRect,
        opacity: 1.0,
        nodeLookup: nodeLookup,
        relations: relations,
        relationEngine: relationEngine,
      );
      borderPaint
        ..color = (containerBorderColor ?? const Color(0xFF64B5F6))
            .withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(resolvedStyle.strokeWidth.toDouble(), 2.0);
      drawDashedRRect(canvas, internalRRect, borderPaint, 16.0, 10.0);
      paintContainerTopLeftTag(
        canvas,
        internalRect,
        1.0,
        containerBaseColor ?? const Color(0xFF64B5F6),
        opacity: 1.0,
      );
      canvas.restore();
    }
  }

  static void paintContainerTitleCentered(
    Canvas canvas,
    Rect rect,
    String title,
    NodeStyle style,
    double opacity,
    double scale,
  ) {
    if (opacity <= 0.0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          fontSize: (style.fontSize * 0.85).clamp(10.0, 14.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(style.textColor).withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16 * scale);

    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
    tp.dispose();
  }

  static void paintContainerInsidePreview({
    required Canvas canvas,
    required ContainerUiNode containerNode,
    required Rect internalRect,
    required RRect internalRRect,
    required double opacity,
    required Map<dynamic, UiNode> nodeLookup,
    required Iterable<UiRelation>? relations,
    required RelationEngineState? relationEngine,
  }) {
    if (opacity <= 0.0) return;
    final children = nodeLookup.values
        .where((n) => n.parentContainerId == containerNode.id)
        .toList();
    if (children.isEmpty) return;

    final double clampedOpacity = opacity.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRRect(internalRRect);
    canvas.saveLayer(
      internalRect,
      Paint()
        ..color = Color.fromARGB(
          (255 * clampedOpacity).round(),
          255,
          255,
          255,
        ),
    );

    // 1. Draw relations between inside children
    if (relations != null) {
      final childIds = children.map((c) => c.id).toSet();
      for (final rel in relations) {
        if (childIds.contains(rel.fromNodeId) &&
            childIds.contains(rel.toNodeId)) {
          paintChildRelation(
            canvas: canvas,
            rel: rel,
            nodeLookup: nodeLookup,
            relationEngine: relationEngine,
          );
        }
      }
    }

    // 2. Draw child nodes
    for (final child in children) {
      paintChildNodePreview(canvas: canvas, child: child);
    }

    canvas.restore();
    canvas.restore();
  }

  static void paintChildRelation({
    required Canvas canvas,
    required UiRelation rel,
    required Map<dynamic, UiNode> nodeLookup,
    required RelationEngineState? relationEngine,
  }) {
    final fromNode = nodeLookup[rel.fromNodeId];
    final toNode = nodeLookup[rel.toNodeId];
    if (fromNode == null || toNode == null) return;

    final resolved = RelationStyleStrategy.resolveStyle(rel);
    final cached = relationEngine?.cache[rel.id];

    final strokeColor = resolved.strokeColor != 0
        ? Color(resolved.strokeColor)
        : const Color(0xFF64B5F6);
    final strokeWidth =
        resolved.strokeWidth > 0 ? resolved.strokeWidth.toDouble() : 2.0;

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (cached != null && cached.pathPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(cached.pathPoints.first.x, cached.pathPoints.first.y);
      for (int i = 1; i < cached.pathPoints.length; i++) {
        path.lineTo(cached.pathPoints[i].x, cached.pathPoints[i].y);
      }
      if (resolved.strokePattern == 'dashed' ||
          resolved.strokePattern == 'dotted') {
        final dashLen = resolved.strokePattern == 'dashed' ? 8.0 : 2.0;
        final gapLen = resolved.strokePattern == 'dashed' ? 6.0 : 4.0;
        final dashedPath = Path();
        for (final metric in path.computeMetrics()) {
          double distance = 0.0;
          while (distance < metric.length) {
            final len = math.min(dashLen, metric.length - distance);
            dashedPath.addPath(
              metric.extractPath(distance, distance + len),
              Offset.zero,
            );
            distance += dashLen + gapLen;
          }
        }
        canvas.drawPath(dashedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    } else {
      final fromCenter = fromNode.position +
          Offset(
            (fromNode.size.width > 0 ? fromNode.size.width : 100.0) / 2,
            (fromNode.size.height > 0 ? fromNode.size.height : 80.0) / 2,
          );
      final toCenter = toNode.position +
          Offset(
            (toNode.size.width > 0 ? toNode.size.width : 100.0) / 2,
            (toNode.size.height > 0 ? toNode.size.height : 80.0) / 2,
          );
      canvas.drawLine(fromCenter, toCenter, paint);
    }
  }

  static void paintChildNodePreview({
    required Canvas canvas,
    required UiNode child,
  }) {
    final childPos = child.position;
    final childStyle =
        child.resolvedStyle ?? NodeStyleStrategy.resolveStyle(child);
    final childSize = (child.size.width > 0 && child.size.height > 0)
        ? child.size
        : const DefaultNodeLayoutStrategy().calculateSize(child).size;
    final childRect = Rect.fromLTWH(
      childPos.dx,
      childPos.dy,
      childSize.width,
      childSize.height,
    );
    final childRRect =
        ShapeNodeRenderer.buildRRect(childRect, childStyle, 0.0, 1.0);

    if (child is DrawingUiNode) {
      ShapeNodeRenderer.paintDrawingPaths(
        canvas,
        child,
        childPos,
        childStyle,
        childSize,
        isHighlighted: false,
        isEditing: false,
        isSelected: false,
        isHovered: false,
        selectionColor: Colors.blueAccent,
        hoverColor: const Color(0xFF64B5F6),
      );
    } else if (child is ContainerUiNode) {
      final childBaseColor = getContainerBaseColor(child, childStyle);
      final hsl = HSLColor.fromColor(childBaseColor);
      final childBorderColor = hsl
          .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
          .withLightness(hsl.lightness.clamp(0.4, 0.75))
          .toColor()
          .withValues(alpha: 0.85);
      final childBgColor = hsl
          .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.08);

      canvas.drawRRect(childRRect, Paint()..color = childBgColor);
      final childBorderPaint = Paint()
        ..color = childBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(childStyle.strokeWidth.toDouble(), 2.0);
      drawDashedRRect(canvas, childRRect, childBorderPaint, 16.0, 10.0);
      paintContainerTitleCentered(
        canvas,
        childRect,
        child.title,
        childStyle,
        1.0,
        1.0,
      );
    } else {
      // Background & Shadow
      if (childStyle.shadowBlur > 0) {
        final shadowOffset =
            Offset(childStyle.shadowOffsetX, childStyle.shadowOffsetY);
        final shadowRRect = ShapeNodeRenderer.buildRRect(
          childRect.shift(shadowOffset),
          childStyle,
          0.0,
          1.0,
        );
        canvas.drawRRect(
          shadowRRect,
          Paint()
            ..color = Color(childStyle.shadowColor)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, childStyle.shadowBlur),
        );
      }
      canvas.drawRRect(childRRect, Paint()..color = Color(childStyle.bgColor));
      canvas.drawRRect(
        childRRect,
        Paint()
          ..color = Color(childStyle.strokeColor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = childStyle.strokeWidth.toDouble(),
      );

      // Text Content
      if (child.content.text.isNotEmpty) {
        TextNodeRenderer.paintPreviewText(
          canvas,
          child.content,
          childRect,
          childStyle,
        );
      }
    }
  }
}
