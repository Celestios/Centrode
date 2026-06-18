import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/viewport_state.dart';
import '../../../presentation/view_state.dart';
import '../../../models/models.dart';
import '../node_visual_constants.dart';

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

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.read<GraphDataQuery>();
    final uiState = context.watch<NodeRenderState>();
    final viewport = context.read<ViewportController>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: viewport.visibleNodeIds,
      builder: (context, visibleIds, _) {
        final renderStack = uiState.zOrder
            .where(visibleIds.contains)
            .toList();

        final entries = renderStack.map((id) {
          final node = query.nodeLookup[id]!;
          final viewState = uiState.viewStates[id]!;
          final isSelected = uiState.selectedEntities.contains(id);
          final isEditing = uiState.activeEditId == id;

          return NodeRenderEntry(
            node: node,
            viewState: viewState,
            isSelected: isSelected,
            isEditing: isEditing,
          );
        }).toList();

        return _CanvasNodesHost(
          entries: entries,
        );
      },
    );
  }
}

class _CanvasNodesHost extends StatefulWidget {
  final List<NodeRenderEntry> entries;

  const _CanvasNodesHost({
    required this.entries,
  });

  @override
  State<_CanvasNodesHost> createState() => _CanvasNodesHostState();
}

class _CanvasNodesHostState extends State<_CanvasNodesHost> {
  final Set<String> _dirtyNodeIds = {};
  final Map<String, VoidCallback> _listeners = {};
  _CanvasNodesPainter? _painter;
  final ValueNotifier<int> _repaintTrigger = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _subscribeAll();
    _createPainter();
  }

  @override
  void didUpdateWidget(covariant _CanvasNodesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unsubscribeAll();
    _subscribeAll();
    _painter!.entries = widget.entries;
    _painter!._entriesGeneration++;
    _repaintTrigger.value++;
  }

  @override
  void dispose() {
    _unsubscribeAll();
    _repaintTrigger.dispose();
    _painter?._cachedPicture?.dispose();
    super.dispose();
  }

  void _createPainter() {
    _painter = _CanvasNodesPainter(
      entries: widget.entries,
      dirtyNodeIds: _dirtyNodeIds,
    );
  }

  void _subscribeAll() {
    for (final entry in widget.entries) {
      final id = entry.node.id;
      void markDirty() {
        _dirtyNodeIds.add(id);
        _repaintTrigger.value++;
      }
      entry.viewState.positionNotifier.addListener(markDirty);
      entry.viewState.sizeNotifier.addListener(markDirty);
      entry.viewState.dragWidthNotifier.addListener(markDirty);
      _listeners[id] = markDirty;
    }
  }

  void _unsubscribeAll() {
    for (final entry in widget.entries) {
      final listener = _listeners.remove(entry.node.id);
      if (listener != null) {
        entry.viewState.positionNotifier.removeListener(listener);
        entry.viewState.sizeNotifier.removeListener(listener);
        entry.viewState.dragWidthNotifier.removeListener(listener);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _repaintTrigger,
      builder: (context, _, __) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              size: size,
              painter: _painter,
            );
          },
        );
      },
    );
  }
}

class _CanvasNodesPainter extends CustomPainter {
  List<NodeRenderEntry> entries;
  final Set<String> dirtyNodeIds;

  ui.Picture? _cachedPicture;
  int _entriesGeneration = 0;
  int _cachedGeneration = -1;

  final Map<String, TextPainter> _textPainterCache = {};
  final Map<String, String> _textCacheKeys = {};
  final Map<String, double> _textMaxWidthCache = {};
  final Map<String, (RRect, RRect)> _handleCache = {};
  final Paint _shadowPaint = Paint();
  final Paint _bgPaint = Paint();
  final Paint _borderPaint = Paint();
  final Paint _handlePaint = Paint()..color = Color(NodeVisualConstants.handleColor);
  late final TextPainter _showMorePainter = TextPainter(
    text: TextSpan(
      text: 'Show More',
      style: TextStyle(fontSize: NodeVisualConstants.expandToggleFontSize, color: Colors.blueAccent, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  );
  late final TextPainter _showLessPainter = TextPainter(
    text: TextSpan(
      text: 'Show Less',
      style: TextStyle(fontSize: NodeVisualConstants.expandToggleFontSize, color: Colors.blueAccent, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  );

  _CanvasNodesPainter({
    required this.entries,
    required this.dirtyNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeIds = <String>{};

    // If cache is valid and no nodes changed, replay cached picture
    final bool cacheValid = _cachedPicture != null &&
        _cachedGeneration == _entriesGeneration &&
        dirtyNodeIds.isEmpty;
    if (cacheValid) {
      canvas.drawPicture(_cachedPicture!);
      return;
    }

    // Full repaint — record into a Picture for future replay
    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);

    for (final entry in entries) {
      activeIds.add(entry.node.id);
      _paintNode(recordCanvas, entry);
    }

    _cachedPicture?.dispose();
    _cachedPicture = recorder.endRecording();
    _cachedGeneration = _entriesGeneration;
    dirtyNodeIds.clear();

    // Draw the newly recorded picture onto the real canvas
    canvas.drawPicture(_cachedPicture!);

    for (final id in _textPainterCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        _textPainterCache[id]!.dispose();
        _textPainterCache.remove(id);
        _textCacheKeys.remove(id);
        _textMaxWidthCache.remove(id);
        _handleCache.remove(id);
      }
    }
  }

  TextPainter _getTextPainter(String nodeId, String text, TextStyle style, int? maxLines, double maxWidth) {
    final key = '${text.hashCode}_${style.hashCode}_$maxLines';

    final cached = _textPainterCache[nodeId];
    if (cached != null && _textCacheKeys[nodeId] == key) {
      final lastMaxWidth = _textMaxWidthCache[nodeId] ?? 0.0;
      if ((lastMaxWidth - maxWidth).abs() < 1.0) {
        return cached;
      }
      cached.layout(maxWidth: maxWidth);
      _textMaxWidthCache[nodeId] = maxWidth;
      return cached;
    }

    cached?.dispose();

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    );

    painter.layout(maxWidth: maxWidth);
    _textPainterCache[nodeId] = painter;
    _textCacheKeys[nodeId] = key;
    _textMaxWidthCache[nodeId] = maxWidth;
    return painter;
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
    final double strokeWidth =
        isHighlighted ? 3.0 : resolvedStyle.strokeWidth.toDouble();
    final double strokeDiff =
        isHighlighted ? (3.0 - resolvedStyle.strokeWidth.toDouble()) : 0.0;

    final expandedRect = rect.inflate(strokeDiff);

    // Shadow
    if (entry.isEditing) {
      _shadowPaint.color = Color(NodeVisualConstants.editingShadowColor);
      _shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    } else if (entry.isSelected) {
      _shadowPaint.color = Color(NodeVisualConstants.selectedShadowColor);
      _shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    } else {
      _shadowPaint.color = Color(resolvedStyle.shadowColor);
      _shadowPaint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, resolvedStyle.shadowBlur);
    }

    final rrect = _buildRRect(expandedRect, resolvedStyle);
    canvas.drawRRect(rrect, _shadowPaint);

    // Background
    _bgPaint.color = Color(resolvedStyle.bgColor);
    canvas.drawRRect(rrect, _bgPaint);

    // Border
    _borderPaint
      ..color = entry.isEditing
          ? Color(NodeVisualConstants.editingBorderColor)
          : (entry.isSelected
              ? Color(NodeVisualConstants.selectedBorderColor)
              : Color(resolvedStyle.strokeColor))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, _borderPaint);

    // Text
    _paintText(canvas, entry, rect, resolvedStyle);

    // Resize handles
    _paintResizeHandles(canvas, node.id, rect, resolvedStyle);

    // Metadata sphere
    _paintMetadataSphere(canvas, node, rect);

    // Expand toggle
    _paintExpandToggle(canvas, entry, rect);
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
    final content = entry.node.content;
    if (content.text.isEmpty) return;

    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontFamily:
          style.fontFamily.isEmpty || style.fontFamily == 'System'
              ? null
              : style.fontFamily,
      color: Color(style.textColor),
    );

    final maxWidth = rect.width - style.padding * 2;
    final maxLines = entry.viewState.isExpandedNotifier.value ? null : 3;

    final textPainter = _getTextPainter(
      entry.node.id,
      content.text,
      textStyle,
      maxLines,
      maxWidth,
    );

    textPainter.paint(
      canvas,
      Offset(rect.left + style.padding, rect.top + style.padding),
    );
  }

  (RRect, RRect) _getHandleRRects(String nodeId, Rect rect, double borderRadius) {
    final cached = _handleCache[nodeId];
    if (cached != null) {
      final (right, left) = cached;
      if (right.outerRect == Rect.fromLTRB(rect.right - NodeVisualConstants.handleWidth, rect.top + NodeVisualConstants.handleTopOffset, rect.right, rect.bottom) &&
          left.outerRect == Rect.fromLTRB(rect.left, rect.top, rect.left + NodeVisualConstants.handleWidth, rect.bottom)) {
        return cached;
      }
    }

    final r = Radius.circular(borderRadius);
    final rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.right - NodeVisualConstants.handleWidth, rect.top + NodeVisualConstants.handleTopOffset, rect.right, rect.bottom),
      topRight: r,
      bottomRight: r,
    );
    final leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.left, rect.top, rect.left + NodeVisualConstants.handleWidth, rect.bottom),
      topLeft: r,
      bottomLeft: r,
    );

    final result = (rightHandle, leftHandle);
    _handleCache[nodeId] = result;
    return result;
  }

  void _paintResizeHandles(Canvas canvas, String nodeId, Rect rect, NodeStyle style) {
    final (rightHandle, leftHandle) = _getHandleRRects(nodeId, rect, style.borderRadius);
    canvas.drawRRect(rightHandle, _handlePaint);
    canvas.drawRRect(leftHandle, _handlePaint);
  }

  void _paintMetadataSphere(Canvas canvas, UiNode node, Rect rect) {
    if (node is! InfoUiNode) return;
    if (node.tags.isEmpty && node.comments.isEmpty) return;

    final center = Offset(rect.right - 10, rect.top + 10);
    const r = 5.0;

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
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r, borderPaint);
  }

  void _paintExpandToggle(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
  ) {
    if (entry.viewState.lineCount <= 3) return;

    final textPainter = entry.viewState.isExpandedNotifier.value
        ? _showLessPainter
        : _showMorePainter;

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(rect.center.dx - textPainter.width / 2, rect.bottom - NodeVisualConstants.expandToggleBottomOffset),
    );
  }

  @override
  bool shouldRepaint(covariant _CanvasNodesPainter oldDelegate) {
    return dirtyNodeIds.isNotEmpty || _entriesGeneration != _cachedGeneration;
  }
}
