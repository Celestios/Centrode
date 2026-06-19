import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/viewport_state.dart';
import '../../../presentation/view_state.dart';
import '../../../models/models.dart';
import '../../../engine/config.dart';
import '../node_visual_constants.dart';
import '../node_widget.dart';
import '../../../presentation/strategies/node_text_span_builder.dart';
import '../../../presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/shared/widgets/unbounded_stack.dart';

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

        final entries = <NodeRenderEntry>[];
        NodeRenderEntry? editingEntry;

        for (final id in renderStack) {
          final node = query.nodeLookup[id]!;
          final viewState = uiState.viewStates[id]!;
          final isSelected = uiState.selectedEntities.contains(id);
          final isEditing = uiState.activeEditId == id;

          final entry = NodeRenderEntry(
            node: node,
            viewState: viewState,
            isSelected: isSelected,
            isEditing: isEditing,
          );

          if (isEditing) {
            editingEntry = entry;
          }
          entries.add(entry);
        }

        return UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: _CanvasNodesHost(entries: entries),
            ),
            if (editingEntry != null)
              Builder(
                builder: (context) {
                  final entry = editingEntry!;
                  return ListenableBuilder(
                    listenable: Listenable.merge([
                      entry.viewState.positionNotifier,
                      entry.viewState.sizeNotifier,
                      entry.viewState.dragWidthNotifier,
                    ]),
                    builder: (context, _) {
                      final pos = entry.viewState.positionNotifier.value;
                      final rawSize = entry.viewState.sizeNotifier.value;
                      final size = Size(
                        entry.viewState.dragWidthNotifier.value ?? rawSize.width,
                        rawSize.height,
                      );
                      final resolvedStyle = entry.node.resolvedStyle;
                      final borderRadius = resolvedStyle?.borderRadius ?? 8.0;
                      final shape = resolvedStyle?.shape ?? 'rectangle';
                      final double fontSize = resolvedStyle?.fontSize ?? 14.0;
                      final double scale = NodeVisualConstants.fontScale(fontSize);

                      return Positioned(
                        key: ValueKey('edit_${entry.node.id}'),
                        left: pos.dx,
                        top: pos.dy,
                        child: HighlightFrame(
                          isEditing: true,
                          isSelected: entry.isSelected,
                          borderRadius: borderRadius,
                          shape: shape,
                          size: size,
                          scale: scale,
                          child: NodeWidget(
                            viewState: entry.viewState,
                            node: entry.node,
                            isSelected: entry.isSelected,
                            isEditing: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
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
  bool _disposed = false;

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
    _disposed = true;
    _unsubscribeAll();
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
        if (_disposed) return;
        _dirtyNodeIds.add(id);
        _repaintTrigger.value++;
      }
      entry.viewState.positionNotifier.addListener(markDirty);
      entry.viewState.sizeNotifier.addListener(markDirty);
      entry.viewState.dragWidthNotifier.addListener(markDirty);
      entry.viewState.isExpandedNotifier.addListener(markDirty);
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
        entry.viewState.isExpandedNotifier.removeListener(listener);
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

  final Map<String, (RRect, RRect)> _handleCache = {};
  final Paint _shadowPaint = Paint();
  final Paint _bgPaint = Paint();
  final Paint _borderPaint = Paint();
  final Paint _handlePaint = Paint()..color = Color(NodeVisualConstants.handleColor);


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

    for (final id in _handleCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        _handleCache.remove(id);
      }
    }
  }

  void _paintNode(Canvas canvas, NodeRenderEntry entry) {
    if (entry.isEditing) return;
    final node = entry.node;
    final vs = entry.viewState;
    final resolvedStyle = node.resolvedStyle;
    if (resolvedStyle == null) return;

    final pos = vs.positionNotifier.value;
    final rawSize = vs.sizeNotifier.value;
    final w = vs.dragWidthNotifier.value ?? rawSize.width;
    final h = rawSize.height;
    final rect = Rect.fromLTWH(pos.dx, pos.dy, w, h);

    final double scale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
    final bool isHighlighted = entry.isSelected || entry.isEditing;
    final double stroke = (entry.isEditing ? 1.0 : 0.6) * scale;
    final double gap = 1.5 * scale;

    // Shadow
    if (entry.isEditing) {
      _shadowPaint.color = Color(NodeVisualConstants.editingShadowColor);
      _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * scale);
    } else if (entry.isSelected) {
      _shadowPaint.color = Color(NodeVisualConstants.selectedShadowColor);
      _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
    } else {
      _shadowPaint.color = Color(resolvedStyle.shadowColor);
      _shadowPaint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, resolvedStyle.shadowBlur);
    }

    final double shadowOffsetX = resolvedStyle.shadowOffsetX;
    final double shadowOffsetY = resolvedStyle.shadowOffsetY;
    final shadowOffset = Offset(shadowOffsetX, shadowOffsetY);

    final rrect = _buildRRect(rect, resolvedStyle, 0.0, scale);
    if (shadowOffset != Offset.zero) {
      final shadowRRect = _buildRRect(rect.shift(shadowOffset), resolvedStyle, 0.0, scale);
      canvas.drawRRect(shadowRRect, _shadowPaint);
    } else {
      canvas.drawRRect(rrect, _shadowPaint);
    }

    // Background
    _bgPaint.color = Color(resolvedStyle.bgColor);
    canvas.drawRRect(rrect, _bgPaint);

    // Base Border
    _borderPaint
      ..color = Color(resolvedStyle.strokeColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = resolvedStyle.strokeWidth.toDouble();
    canvas.drawRRect(rrect, _borderPaint);

    // Highlight/Editing Border
    if (isHighlighted) {
      final double inflateAmount = gap + stroke / 2;
      final highlightRect = rect.inflate(inflateAmount);
      final highlightRRect = _buildRRect(highlightRect, resolvedStyle, inflateAmount, scale);
      _borderPaint
        ..color = entry.isEditing
            ? Color(NodeVisualConstants.editingBorderColor)
            : Color(NodeVisualConstants.selectedBorderColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawRRect(highlightRRect, _borderPaint);
    }

    // Text
    _paintText(canvas, entry, rect, resolvedStyle);

    // Resize handles
    _paintResizeHandles(canvas, node.id, rect, resolvedStyle, scale);

    // Metadata sphere
    _paintMetadataSphere(canvas, node, rect, scale);

    // Expand toggle
    _paintExpandToggle(canvas, entry, rect, resolvedStyle, scale);
  }

  RRect _buildRRect(Rect rect, NodeStyle style, [double extraRadius = 0.0, double scale = 1.0]) {
    final radius = style.shape == 'circle'
        ? Radius.circular(rect.shortestSide / 2)
        : Radius.circular(style.borderRadius + extraRadius);
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

    final baseStyle = TextStyle(
      fontSize: style.fontSize,
      fontFamily:
          style.fontFamily.isEmpty || style.fontFamily == 'System'
              ? null
              : style.fontFamily,
      color: Color(style.textColor),
    );

    final maxWidth = rect.width - style.padding * 2;
    final blockSpans = NodeTextSpanBuilder.buildPerBlockTextSpans(
      content,
      baseStyle,
    );

    final maxLines = entry.viewState.isExpandedNotifier.value ? null : 3;
    int totalLinesPainted = 0;

    final List<TextPainter> painters = [];
    double totalTextHeight = 0.0;

    for (final (span, textAlign) in blockSpans) {
      if (maxLines != null && totalLinesPainted >= maxLines) break;

      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: maxLines != null ? maxLines - totalLinesPainted : null,
        ellipsis: maxLines != null ? '...' : null,
      )..layout(minWidth: maxWidth, maxWidth: maxWidth);

      painters.add(tp);
      totalTextHeight += tp.height;
      totalLinesPainted += tp.computeLineMetrics().length;
    }

    final fontScale = style.fontSize / 14.0;
    double extraHeight = 0.0;
    if (entry.node is TaskUiNode) {
      extraHeight += NodeStyleStrategy.taskBadgeHeight(fontScale);
    }
    if (entry.viewState.lineCount > AppConfig.node.collapsedLineLimit) {
      extraHeight += NodeStyleStrategy.expandToggleSpace(entry.viewState.isExpandedNotifier.value, fontScale);
    }

    final yCenter = rect.top + style.padding + (rect.height - style.padding * 2 - extraHeight) / 2;
    double y = yCenter - totalTextHeight / 2;

    for (final tp in painters) {
      tp.paint(canvas, Offset(rect.left + style.padding, y));
      y += tp.height;
      tp.dispose();
    }
  }

  (RRect, RRect) _getHandleRRects(String nodeId, Rect rect, double borderRadius, double scale) {
    final cached = _handleCache[nodeId];
    final double handleWidth = NodeVisualConstants.handleWidth * scale;
    final double handleTopOffset = NodeVisualConstants.handleTopOffset * scale;
    if (cached != null) {
      final (right, left) = cached;
      if (right.outerRect == Rect.fromLTRB(rect.right - handleWidth, rect.top + handleTopOffset, rect.right, rect.bottom) &&
          left.outerRect == Rect.fromLTRB(rect.left, rect.top, rect.left + handleWidth, rect.bottom)) {
        return cached;
      }
    }

    final r = Radius.circular(borderRadius);
    final rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.right - handleWidth, rect.top + handleTopOffset, rect.right, rect.bottom),
      topRight: r,
      bottomRight: r,
    );
    final leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.left, rect.top, rect.left + handleWidth, rect.bottom),
      topLeft: r,
      bottomLeft: r,
    );

    final result = (rightHandle, leftHandle);
    _handleCache[nodeId] = result;
    return result;
  }

  void _paintResizeHandles(Canvas canvas, String nodeId, Rect rect, NodeStyle style, double scale) {
    final (rightHandle, leftHandle) = _getHandleRRects(nodeId, rect, style.borderRadius, scale);
    canvas.drawRRect(rightHandle, _handlePaint);
    canvas.drawRRect(leftHandle, _handlePaint);
  }

  void _paintMetadataSphere(Canvas canvas, UiNode node, Rect rect, double scale) {
    if (node is! InfoUiNode) return;
    if (node.tags.isEmpty && node.comments.isEmpty) return;

    final center = Offset(
      rect.right - AppConfig.node.metadataSphereOffsetFromRight * scale,
      rect.top + AppConfig.node.metadataSphereOffsetFromTop * scale,
    );
    final r = AppConfig.node.metadataSphereRadius * scale;

    final color = NodeVisualConstants.metadataSphereColor(
      hasTags: node.tags.isNotEmpty,
      hasComments: node.comments.isNotEmpty,
    );

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale);
    canvas.drawCircle(center + Offset(0, 1 * scale), r, shadowPaint);

    final fillPaint = Paint()..color = Color(color);
    canvas.drawCircle(center, r, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(center, r, borderPaint);
  }

  void _paintExpandToggle(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
    NodeStyle style,
    double scale,
  ) {
    if (entry.viewState.lineCount <= 3) return;

    final toggleSpace = NodeStyleStrategy.expandToggleSpace(entry.viewState.isExpandedNotifier.value, scale);
    final taskBadgeHeight = entry.node is TaskUiNode ? NodeStyleStrategy.taskBadgeHeight(scale) : 0.0;

    final yCenter = rect.bottom - style.padding - taskBadgeHeight - toggleSpace / 2;

    // Draw background wide narrow button
    final double buttonHeight = 16.0 * scale;
    final double buttonWidth = rect.width - 2 * style.padding;
    final double buttonLeft = rect.left + style.padding;
    final double buttonTop = yCenter - buttonHeight / 2;
    final buttonRect = Rect.fromLTWH(buttonLeft, buttonTop, buttonWidth, buttonHeight);
    final buttonRRect = RRect.fromRectAndRadius(buttonRect, Radius.circular(4.0 * scale));

    final bgPaint = Paint()
      ..color = Color(style.textColor).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(buttonRRect, bgPaint);

    // Draw double arrow icon (without any circle around it)
    final iconData = entry.viewState.isExpandedNotifier.value
        ? Icons.keyboard_double_arrow_up
        : Icons.keyboard_double_arrow_down;

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 12.0 * scale,
          fontFamily: 'MaterialIcons',
          color: Color(style.textColor).withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, yCenter - tp.height / 2),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _CanvasNodesPainter oldDelegate) {
    return dirtyNodeIds.isNotEmpty || _entriesGeneration != _cachedGeneration;
  }
}
