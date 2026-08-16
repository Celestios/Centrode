import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../models/models.dart';
import '../../widgets/node_visual_constants.dart';
import 'shape_node_renderer.dart';

class NodeSelectionRenderer {
  final Map<RawUuid, (RRect, RRect)> handleCache = {};
  final Paint _shadowPaint = Paint();
  final Paint _borderPaint = Paint();
  final Paint _handlePaint = Paint()
    ..color = Color(NodeVisualConstants.handleColor);

  NodeSelectionRenderer();

  void paintShadow(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    NodeStyle resolvedStyle, {
    required bool isEditing,
    required bool isSelected,
    required double fontScale,
  }) {
    if (isEditing) {
      _shadowPaint.color = Color(NodeVisualConstants.editingShadowColor);
      _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * fontScale);
    } else if (isSelected) {
      _shadowPaint.color = Color(NodeVisualConstants.selectedShadowColor);
      _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * fontScale);
    } else {
      _shadowPaint.color = Color(resolvedStyle.shadowColor);
      _shadowPaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        resolvedStyle.shadowBlur,
      );
    }

    final double shadowOffsetX = resolvedStyle.shadowOffsetX;
    final double shadowOffsetY = resolvedStyle.shadowOffsetY;
    final shadowOffset = Offset(shadowOffsetX, shadowOffsetY);

    if (shadowOffset != Offset.zero) {
      final shadowRRect = ShapeNodeRenderer.buildRRect(
        rect.shift(shadowOffset),
        resolvedStyle,
        0.0,
        fontScale,
      );
      canvas.drawRRect(shadowRRect, _shadowPaint);
    } else {
      canvas.drawRRect(rrect, _shadowPaint);
    }
  }

  void paintHighlightBorder(
    Canvas canvas,
    Rect rect,
    NodeStyle resolvedStyle, {
    required bool isEditing,
    required bool isSelected,
    required double stroke,
    required double gap,
    required double fontScale,
    required Color selectionColor,
    required Color hoverColor,
  }) {
    final double inflateAmount = gap + stroke / 2;
    final highlightRect = rect.inflate(inflateAmount);
    final highlightRRect = ShapeNodeRenderer.buildRRect(
      highlightRect,
      resolvedStyle,
      inflateAmount,
      fontScale,
    );

    final Color highlightColor;
    if (isEditing) {
      highlightColor = Color(NodeVisualConstants.editingBorderColor);
    } else if (isSelected) {
      highlightColor = selectionColor;
    } else {
      highlightColor = hoverColor;
    }

    _borderPaint
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawRRect(highlightRRect, _borderPaint);
  }

  (RRect, RRect) getHandleRRects(
    RawUuid nodeId,
    Rect rect,
    double borderRadius,
    double scale,
    bool hasMetadataSphere,
  ) {
    final cached = handleCache[nodeId];
    final double handleWidth = NodeVisualConstants.handleWidth * scale;
    final double handleTopOffset = hasMetadataSphere
        ? NodeVisualConstants.handleTopOffset * scale
        : 0.0;
    if (cached != null) {
      final (right, left) = cached;
      if (right.outerRect ==
              Rect.fromLTRB(
                rect.right - handleWidth,
                rect.top + handleTopOffset,
                rect.right,
                rect.bottom,
              ) &&
          left.outerRect ==
              Rect.fromLTRB(
                rect.left,
                rect.top,
                rect.left + handleWidth,
                rect.bottom,
              )) {
        return cached;
      }
    }

    final r = Radius.circular(borderRadius);
    final rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        rect.right - handleWidth,
        rect.top + handleTopOffset,
        rect.right,
        rect.bottom,
      ),
      topRight: r,
      bottomRight: r,
    );
    final leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.left, rect.top, rect.left + handleWidth, rect.bottom),
      topLeft: r,
      bottomLeft: r,
    );

    final result = (rightHandle, leftHandle);
    handleCache[nodeId] = result;
    return result;
  }

  void paintResizeHandles(
    Canvas canvas,
    RawUuid nodeId,
    Rect rect,
    NodeStyle style,
    double scale,
    bool hasMetadataSphere,
  ) {
    final (rightHandle, leftHandle) = getHandleRRects(
      nodeId,
      rect,
      style.borderRadius,
      scale,
      hasMetadataSphere,
    );
    canvas.drawRRect(rightHandle, _handlePaint);
    canvas.drawRRect(leftHandle, _handlePaint);
  }

  void cleanupHandles(Set<RawUuid> activeIds) {
    for (final id in handleCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        handleCache.remove(id);
      }
    }
  }

  void clearHandles() {
    handleCache.clear();
  }
}
