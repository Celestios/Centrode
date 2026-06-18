import 'package:flutter/material.dart';
import '../../engine/config.dart';
import '../../models/models.dart';
import '../../presentation/view_state.dart';
import 'node_hit_result.dart';
import 'grid_hash.dart';

class NodeRenderEntry {
  final UiNode node;
  final NodeViewState viewState;
  final bool isSelected;
  final bool isEditing;

  const NodeRenderEntry({
    required this.node,
    required this.viewState,
    required this.isSelected,
    required this.isEditing,
  });
}

class RenderCanvasNodes extends RenderBox {
  List<NodeRenderEntry> _entries = [];
  String? _hoveredNodeId;
  final GridHash _grid = GridHash();
  final List<VoidCallback> _listenerDisposables = [];

  set entries(List<NodeRenderEntry> value) {
    if (_entries == value) return;

    for (final cb in _listenerDisposables) {
      cb();
    }
    _listenerDisposables.clear();
    _grid.clear();

    _entries = value;

    for (final entry in _entries) {
      final rect = entry.viewState.rect;
      _grid.insert(entry.node.id, rect);

      void listen() {
        _grid.update(entry.node.id, entry.viewState.rect);
        markNeedsPaint();
      }

      entry.viewState.positionNotifier.addListener(listen);
      entry.viewState.sizeNotifier.addListener(listen);
      _listenerDisposables.add(() {
        entry.viewState.positionNotifier.removeListener(listen);
        entry.viewState.sizeNotifier.removeListener(listen);
      });
    }

    markNeedsLayout();
    markNeedsPaint();
  }

  set hoveredNodeId(String? value) {
    if (_hoveredNodeId == value) return;
    _hoveredNodeId = value;
    markNeedsPaint();
  }

  @override
  void dispose() {
    for (final cb in _listenerDisposables) {
      cb();
    }
    _listenerDisposables.clear();
    _grid.clear();
    super.dispose();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    for (final entry in _entries) {
      _paintNode(canvas, entry);
    }

    canvas.restore();
  }

  void _paintNode(Canvas canvas, NodeRenderEntry entry) {
    final node = entry.node;
    final vs = entry.viewState;
    final resolvedStyle = node.resolvedStyle;
    if (resolvedStyle == null) return;

    final pos = vs.positionNotifier.value;
    final rawSize = vs.sizeNotifier.value;
    final w = vs.dragWidthNotifier.value ?? rawSize.width;
    final h = rawSize.height;
    final rect = Rect.fromLTWH(pos.dx, pos.dy, w, h);

    final bool isHighlighted = entry.isSelected || entry.isEditing;
    final double strokeWidth = isHighlighted
        ? 3.0
        : resolvedStyle.strokeWidth.toDouble();
    final double strokeDiff = isHighlighted
        ? (3.0 - resolvedStyle.strokeWidth.toDouble())
        : 0.0;

    final expandedRect = rect.inflate(strokeDiff);

    // Shadow
    final shadowPaint = Paint();
    if (entry.isEditing) {
      shadowPaint.color = const Color(0x602196F3);
      shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    } else if (entry.isSelected) {
      shadowPaint.color = const Color(0x4442A5F5);
      shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    } else {
      shadowPaint.color = Color(resolvedStyle.shadowColor);
      shadowPaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        resolvedStyle.shadowBlur,
      );
    }

    final rrect = _buildRRect(expandedRect, resolvedStyle);
    canvas.drawRRect(rrect, shadowPaint);

    // Background
    final bgPaint = Paint()..color = Color(resolvedStyle.bgColor);
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = entry.isEditing
          ? const Color(0xFF2196F3)
          : (entry.isSelected
              ? AppConfig.visuals.selectionAccent
              : Color(resolvedStyle.strokeColor))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, borderPaint);

    // Text
    _paintText(canvas, entry, rect, resolvedStyle);

    // Resize handles
    _paintResizeHandles(canvas, rect, resolvedStyle);

    // Metadata sphere
    _paintMetadataSphere(canvas, node, rect);

    // Expand toggle
    _paintExpandToggle(canvas, entry, rect);

    // Hover highlight
    if (_hoveredNodeId == node.id && !entry.isSelected && !entry.isEditing) {
      final hoverPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, hoverPaint);
    }
  }

  RRect _buildRRect(Rect rect, NodeStyle style) {
    final radius = style.shape == 'circle'
        ? Radius.circular(rect.shortestSide / 2)
        : Radius.circular(style.borderRadius);
    return RRect.fromRectAndRadius(rect, radius);
  }

  void _paintText(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
    NodeStyle style,
  ) {
    final node = entry.node;
    final content = node.content;
    if (content.text.isEmpty) return;

    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontFamily:
          style.fontFamily.isEmpty || style.fontFamily == 'System'
              ? null
              : style.fontFamily,
      color: Color(style.textColor),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: content.text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: entry.viewState.isExpandedNotifier.value
          ? null
          : AppConfig.node.collapsedLineLimit,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: rect.width - style.padding * 2);

    final textOffset = Offset(
      rect.left + style.padding,
      rect.top + style.padding,
    );

    textPainter.paint(canvas, textOffset);
    textPainter.dispose();
  }

  void _paintResizeHandles(
    Canvas canvas,
    Rect rect,
    NodeStyle style,
  ) {
    final handlePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.01);

    // Right handle
    final rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        rect.right - AppConfig.interaction.resizeEdgeWidth,
        rect.top + 24.0,
        rect.right,
        rect.bottom,
      ),
      topRight: Radius.circular(style.borderRadius),
      bottomRight: Radius.circular(style.borderRadius),
    );
    canvas.drawRRect(rightHandle, handlePaint);

    // Left handle
    final leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.left + AppConfig.interaction.resizeEdgeWidth,
        rect.bottom,
      ),
      topLeft: Radius.circular(style.borderRadius),
      bottomLeft: Radius.circular(style.borderRadius),
    );
    canvas.drawRRect(leftHandle, handlePaint);
  }

  void _paintMetadataSphere(Canvas canvas, UiNode node, Rect rect) {
    if (node is! InfoUiNode) return;
    if (node.tags.isEmpty && node.comments.isEmpty) return;

    final center = Offset(
      rect.right - AppConfig.node.metadataSphereOffsetFromRight,
      rect.top + AppConfig.node.metadataSphereOffsetFromTop,
    );
    final r = AppConfig.node.metadataSphereRadius;

    final color = (node.tags.isNotEmpty && node.comments.isNotEmpty)
        ? 0xFFEC407A
        : node.tags.isNotEmpty
            ? 0xFF5C6BC0
            : 0xFF26A69A;

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center + const Offset(0, 1), r, shadowPaint);

    final fillPaint = Paint()..color = Color(color);
    canvas.drawCircle(center, r, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConfig.node.metadataSphereStrokeWidth;
    canvas.drawCircle(center, r, borderPaint);
  }

  void _paintExpandToggle(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
  ) {
    if (entry.viewState.lineCount <= 3) return;

    final text = entry.viewState.isExpandedNotifier.value
        ? "Show Less"
        : "Show More";

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      rect.center.dx - textPainter.width / 2,
      rect.bottom - 20,
    );

    textPainter.paint(canvas, textOffset);
    textPainter.dispose();
  }

  NodeHitResult? hitTestNodes(Offset position) {
    final candidateIds = _grid.query(position);

    for (final nodeId in candidateIds) {
      final entry = _entries.firstWhere(
        (e) => e.node.id == nodeId,
        orElse: () => _entries.first,
      );

      final vs = entry.viewState;
      final pos = vs.positionNotifier.value;
      final rawSize = vs.sizeNotifier.value;
      final w = vs.dragWidthNotifier.value ?? rawSize.width;
      final h = rawSize.height;
      final rect = Rect.fromLTWH(pos.dx, pos.dy, w, h);

      if (!rect.contains(position)) continue;

      // Check resize handles
      if (position.dx >= rect.right - AppConfig.interaction.resizeEdgeWidth &&
          position.dy >= rect.top + 24.0) {
        return NodeHitResult(nodeId, HitElement.resizeRight);
      }
      if (position.dx <= rect.left + AppConfig.interaction.resizeEdgeWidth) {
        return NodeHitResult(nodeId, HitElement.resizeLeft);
      }

      // Check expand toggle
      if (vs.lineCount > 3 &&
          position.dy >= rect.bottom - 24 &&
          position.dy <= rect.bottom) {
        return NodeHitResult(nodeId, HitElement.expandToggle);
      }

      // Check metadata sphere
      if (entry.node is InfoUiNode) {
        final infoNode = entry.node as InfoUiNode;
        if (infoNode.tags.isNotEmpty || infoNode.comments.isNotEmpty) {
          final center = Offset(
            rect.right - AppConfig.node.metadataSphereOffsetFromRight,
            rect.top + AppConfig.node.metadataSphereOffsetFromTop,
          );
          if ((position - center).distance <
              AppConfig.node.metadataSphereHitboxRadius) {
            return NodeHitResult(nodeId, HitElement.metadataSphere);
          }
        }
      }

      // Default: body hit
      return NodeHitResult(nodeId, HitElement.body);
    }

    return null;
  }
}
